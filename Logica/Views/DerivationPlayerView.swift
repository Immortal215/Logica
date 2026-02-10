import SwiftUI
import Combine

struct DerivationPlayerView: View {
    let page: MathPage
    let derivation: DerivationSpec
    let interactiveSpec: VisualSpec?

    @ObservedObject var store: MathWikiStore

    @StateObject var playback: DefaultDerivationPlaybackController
    @State var graphParameters: [String: Double]

    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    init(page: MathPage, derivation: DerivationSpec, visual: VisualSpec?, store: MathWikiStore) {
        self.page = page
        self.derivation = derivation
        self.store = store

        if let interactiveModelID = derivation.interactiveModelID {
            let fallbackMetadata = [
                "xMin": "-10",
                "xMax": "10",
                "yMin": "-10",
                "yMax": "10"
            ]

            interactiveSpec = VisualSpec(
                id: "interactive-\(derivation.id)",
                kind: .graph2D,
                modelID: interactiveModelID,
                parameters: visual?.parameters ?? [],
                metadata: visual?.metadata ?? fallbackMetadata
            )
        } else if let visual, visual.kind == .graph2D {
            interactiveSpec = visual
        } else {
            interactiveSpec = nil
        }

        _playback = StateObject(wrappedValue: DefaultDerivationPlaybackController(stepCount: derivation.steps.count))
        _graphParameters = State(initialValue: interactiveSpec?.parameters.reduce(into: [String: Double]()) { partial, parameter in
            partial[parameter.id] = parameter.defaultValue
        } ?? [:])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Derivation")
                    .font(.headline)
                Spacer()
                Button(playback.isPlaying ? "Pause" : "Play") {
                    playback.isPlaying.toggle()
                }
                .buttonStyle(.bordered)

                Button("Reset") {
                    playback.reset()
                }
                .buttonStyle(.bordered)
            }

            if derivation.steps.count > 1 {
                Slider(
                    value: Binding(
                        get: { Double(playback.currentStep) },
                        set: { playback.currentStep = Int($0.rounded()) }
                    ),
                    in: 0...Double(max(derivation.steps.count - 1, 0)),
                    step: 1
                )
            }

            currentStepCard

            if let interactiveSpec {
                derivationGraph(spec: interactiveSpec)
            }

            stepList
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .onReceive(timer) { _ in
            playback.tick()
        }
    }

    var currentStepCard: some View {
        let step = derivation.steps[playback.currentStep]

        return VStack(alignment: .leading, spacing: 8) {
            Text("Step \(playback.currentStep + 1) of \(derivation.steps.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(LatexFormatter.render(step.equation))
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(store.linkedAttributedText(
                source: step.explanationMarkdown,
                cacheKey: "step:\(page.id):\(playback.currentStep)",
                currentPageID: page.id
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: playback.currentStep)
    }

    func derivationGraph(spec: VisualSpec) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interactive Model")
                .font(.subheadline.weight(.semibold))

            GraphCanvasPlot(
                model: GraphModelRegistry.model(for: spec.modelID),
                parameters: graphParameters,
                viewport: GraphModelRegistry.viewport(for: spec)
            )
            .frame(height: 210)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator), lineWidth: 1)
            }

            ForEach(spec.parameters) { parameter in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(parameter.label)
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(String(format: "%.2f", graphParameters[parameter.id] ?? parameter.defaultValue))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { graphParameters[parameter.id] ?? parameter.defaultValue },
                            set: { graphParameters[parameter.id] = $0 }
                        ),
                        in: parameter.min...parameter.max,
                        step: parameter.step
                    )
                }
            }
        }
    }

    var stepList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Steps")
                .font(.subheadline.weight(.semibold))

            ForEach(Array(derivation.steps.enumerated()), id: \.offset) { index, step in
                Button {
                    playback.currentStep = index
                    playback.isPlaying = false
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(LatexFormatter.render(step.equation))
                            .font(.callout.monospaced())
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(8)
                    .background(
                        index == playback.currentStep
                        ? Color.blue.opacity(0.14)
                        : Color(.tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
