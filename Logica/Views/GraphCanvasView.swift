import SwiftUI

struct GraphInteractiveView: View {
    let spec: VisualSpec

    @State var parameters: [String: Double]

    init(spec: VisualSpec) {
        self.spec = spec
        _parameters = State(initialValue: GraphModelRegistry.defaultParameters(for: spec))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GraphCanvasPlot(
                model: GraphModelRegistry.model(for: spec.modelID),
                parameters: parameters,
                viewport: GraphModelRegistry.viewport(for: spec)
            )
            .frame(height: 240)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 1)
            }

            if !spec.parameters.isEmpty {
                ForEach(spec.parameters) { parameter in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(parameter.label)
                                .font(.caption.weight(.semibold))
                            Spacer()
                            Text(formatted(parameters[parameter.id] ?? parameter.defaultValue))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { parameters[parameter.id] ?? parameter.defaultValue },
                                set: { parameters[parameter.id] = $0 }
                            ),
                            in: parameter.min...parameter.max,
                            step: parameter.step
                        )
                    }
                }
            }
        }
    }

    func formatted(_ value: Double) -> String {
        if abs(value) >= 10 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }
}

struct GraphCanvasPlot: View {
    let model: GraphRenderableModel
    let parameters: [String: Double]
    let viewport: GraphViewport

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                drawGrid(context: &context, size: size)
                drawAxes(context: &context, size: size)
                drawCurve(context: &context, size: size)
            }
            .drawingGroup()
        }
    }

    func drawGrid(context: inout GraphicsContext, size: CGSize) {
        let gridLines = 10
        let color = Color.gray.opacity(0.18)

        for index in 0...gridLines {
            let t = CGFloat(index) / CGFloat(gridLines)
            let x = t * size.width
            let y = t * size.height

            var vertical = Path()
            vertical.move(to: CGPoint(x: x, y: 0))
            vertical.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(vertical, with: .color(color), lineWidth: 0.8)

            var horizontal = Path()
            horizontal.move(to: CGPoint(x: 0, y: y))
            horizontal.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(horizontal, with: .color(color), lineWidth: 0.8)
        }
    }

    func drawAxes(context: inout GraphicsContext, size: CGSize) {
        let xZero = mapX(0, width: size.width)
        let yZero = mapY(0, height: size.height)

        if xZero >= 0, xZero <= size.width {
            var yAxis = Path()
            yAxis.move(to: CGPoint(x: xZero, y: 0))
            yAxis.addLine(to: CGPoint(x: xZero, y: size.height))
            context.stroke(yAxis, with: .color(.gray.opacity(0.6)), lineWidth: 1.2)
        }

        if yZero >= 0, yZero <= size.height {
            var xAxis = Path()
            xAxis.move(to: CGPoint(x: 0, y: yZero))
            xAxis.addLine(to: CGPoint(x: size.width, y: yZero))
            context.stroke(xAxis, with: .color(.gray.opacity(0.6)), lineWidth: 1.2)
        }
    }

    func drawCurve(context: inout GraphicsContext, size: CGSize) {
        let samples = min(max(Int(size.width * 1.2), 220), 520)
        let xMin = viewport.xRange.lowerBound
        let xMax = viewport.xRange.upperBound

        var path = Path()
        var didMove = false

        for sample in 0...samples {
            let ratio = Double(sample) / Double(samples)
            let x = xMin + ((xMax - xMin) * ratio)

            guard let y = model.yValue(x: x, params: parameters) else {
                didMove = false
                continue
            }

            let point = CGPoint(x: mapX(x, width: size.width), y: mapY(y, height: size.height))

            if point.y.isNaN || point.y.isInfinite {
                didMove = false
                continue
            }

            if point.y < -2000 || point.y > (size.height + 2000) {
                didMove = false
                continue
            }

            if didMove {
                path.addLine(to: point)
            } else {
                path.move(to: point)
                didMove = true
            }
        }

        context.stroke(path, with: .color(.blue), lineWidth: 2.4)
    }

    func mapX(_ x: Double, width: CGFloat) -> CGFloat {
        let lower = viewport.xRange.lowerBound
        let upper = viewport.xRange.upperBound
        guard upper > lower else { return 0 }
        return CGFloat((x - lower) / (upper - lower)) * width
    }

    func mapY(_ y: Double, height: CGFloat) -> CGFloat {
        let lower = viewport.yRange.lowerBound
        let upper = viewport.yRange.upperBound
        guard upper > lower else { return height }
        let ratio = (y - lower) / (upper - lower)
        return height - (CGFloat(ratio) * height)
    }
}
