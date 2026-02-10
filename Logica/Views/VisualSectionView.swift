import SwiftUI

struct VisualSectionView: View {
    let spec: VisualSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Visual")
                .font(.headline)

            switch spec.kind {
            case .graph2D:
                GraphInteractiveView(spec: spec)
            case .animation:
                AnimationVisualView(title: spec.metadata["title"] ?? "Animation")
            case .lattice:
                LatticeVisualView(title: spec.metadata["title"] ?? "Lattice")
            case .timeline:
                TimelineVisualView(title: spec.metadata["title"] ?? "Timeline")
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AnimationVisualView: View {
    let title: String
    @State var animate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.08))

                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .offset(x: animate ? 120 : -120)

                Circle()
                    .stroke(Color.indigo.opacity(0.6), lineWidth: 2)
                    .frame(width: animate ? 180 : 90, height: animate ? 180 : 90)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
            }
            .frame(height: 180)
            .onAppear {
                animate = true
            }
        }
    }
}

struct LatticeVisualView: View {
    let title: String

    let points: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.1),
        CGPoint(x: 0.25, y: 0.35),
        CGPoint(x: 0.75, y: 0.35),
        CGPoint(x: 0.15, y: 0.65),
        CGPoint(x: 0.5, y: 0.65),
        CGPoint(x: 0.85, y: 0.65),
        CGPoint(x: 0.5, y: 0.9)
    ]

    let edges: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 4), (2, 5), (3, 6), (4, 6), (5, 6)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            GeometryReader { proxy in
                let size = proxy.size

                Canvas { context, _ in
                    for edge in edges {
                        let start = CGPoint(x: points[edge.0].x * size.width, y: points[edge.0].y * size.height)
                        let end = CGPoint(x: points[edge.1].x * size.width, y: points[edge.1].y * size.height)

                        var path = Path()
                        path.move(to: start)
                        path.addLine(to: end)
                        context.stroke(path, with: .color(.gray.opacity(0.55)), lineWidth: 1.5)
                    }

                    for point in points {
                        let center = CGPoint(x: point.x * size.width, y: point.y * size.height)
                        let node = Path(ellipseIn: CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16))
                        context.fill(node, with: .color(.teal))
                    }
                }
            }
            .frame(height: 200)
            .background(Color.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct TimelineVisualView: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.purple.opacity(0.75))
                            .frame(width: 10, height: 10)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.purple.opacity(0.15))
                            .frame(height: 22)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.purple.opacity(0.55))
                                    .frame(width: CGFloat(70 + (index * 45)))
                            }
                    }
                }
            }
            .padding(12)
            .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
