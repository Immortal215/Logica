import Foundation
import Combine

@MainActor
final class DefaultDerivationPlaybackController: ObservableObject, DerivationPlaybackController {
    @Published var currentStep = 0
    @Published var isPlaying = false

    let stepCount: Int

    init(stepCount: Int) {
        self.stepCount = max(stepCount, 1)
    }

    func reset() {
        currentStep = 0
        isPlaying = false
    }

    func tick() {
        guard isPlaying else { return }

        if currentStep < (stepCount - 1) {
            currentStep += 1
        } else {
            isPlaying = false
        }
    }
}
