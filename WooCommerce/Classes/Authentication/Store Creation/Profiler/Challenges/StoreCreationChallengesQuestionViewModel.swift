import Combine
import Foundation

/// Necessary data from the answer of the store creation challenges question.
struct StoreCreationChallengesAnswer: Equatable {
    /// Display name of the selected challenge.
    let name: String
    /// Raw value of the challenge to be sent to the backend.
    let value: String
}

/// View model for `StoreCreationChallengesQuestionView`, an optional profiler question about challenges in the store creation flow.
@MainActor
final class StoreCreationChallengesQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    typealias Answer = StoreCreationChallengesAnswer

    let topHeader = Localization.topHeader

    let title = Localization.title

    let subtitle = Localization.subtitle

    @Published private(set) var selectedChallenges: [Challenge] = []

    private let onContinue: ([Answer]) -> Void
    private let onSkip: () -> Void

    init(onContinue: @escaping ([Answer]) -> Void,
         onSkip: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onSkip = onSkip
    }
}

extension StoreCreationChallengesQuestionViewModel: OptionalStoreCreationProfilerQuestionViewModel {
    func continueButtonTapped() async {
        guard selectedChallenges.isNotEmpty else {
            return onSkip()
        }

        onContinue(selectedChallenges.map { .init(name: $0.name, value: $0.rawValue) })
    }

    func skipButtonTapped() {
        onSkip()
    }
}

extension StoreCreationChallengesQuestionViewModel {
    func didTapChallenge(_ challenge: Challenge) {
        if let alreadySelectedIndex = selectedChallenges.firstIndex(of: challenge) {
            selectedChallenges.remove(at: alreadySelectedIndex)
        } else {
            selectedChallenges.append(challenge)
        }
    }
}

private extension StoreCreationChallengesQuestionViewModel {
    enum Localization {
        static let topHeader = NSLocalizedString(
            "About you",
            comment: "Top header text of the store creation profiler question about the challenges."
        )
        static let title = NSLocalizedString(
            "What challenges you in starting or running an online Store?",
            comment: "Title of the store creation profiler question about the challenges."
        )
        static let subtitle = NSLocalizedString(
            "Choose your concerns or difficulties below. You can select more than one option.",
            comment: "Subtitle of the store creation profiler question about the challenges."
        )
    }
}
