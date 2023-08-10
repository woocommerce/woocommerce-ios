import Combine
import Foundation

/// Necessary data from the answer of the store creation features question.
struct StoreCreationFeaturesAnswer: Equatable {
    /// Display name of the selected feature.
    let name: String
    /// Raw value of the feature to be sent to the backend.
    let value: String
}

/// View model for `StoreCreationFeaturesQuestionView`, an optional profiler question about features in the store creation flow.
final class StoreCreationFeaturesQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    typealias Answer = StoreCreationFeaturesAnswer

    let topHeader = Localization.topHeader

    let title = Localization.title

    let subtitle = Localization.subtitle

    @Published private(set) var selectedFeatures: [Feature] = []

    private let onContinue: ([Answer]) -> Void
    private let onSkip: () -> Void

    init(onContinue: @escaping ([Answer]) -> Void,
         onSkip: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onSkip = onSkip
    }
}

extension StoreCreationFeaturesQuestionViewModel: OptionalStoreCreationProfilerQuestionViewModel {
    @MainActor
    func continueButtonTapped() async {
        guard selectedFeatures.isNotEmpty else {
            return onSkip()
        }

        onContinue(selectedFeatures.map { .init(name: $0.name, value: $0.rawValue) })
    }

    func skipButtonTapped() {
        onSkip()
    }
}

extension StoreCreationFeaturesQuestionViewModel {
    func didTapFeature(_ feature: Feature) {
        if let alreadySelectedIndex = selectedFeatures.firstIndex(of: feature) {
            selectedFeatures.remove(at: alreadySelectedIndex)
        } else {
            selectedFeatures.append(feature)
        }
    }
}

private extension StoreCreationFeaturesQuestionViewModel {
    enum Localization {
        static let topHeader = NSLocalizedString(
            "About you",
            comment: "Top header text of the store creation profiler question about the features."
        )
        static let title = NSLocalizedString(
            "Which features are you most interested in?",
            comment: "Title of the store creation profiler question about the features."
        )
        static let subtitle = NSLocalizedString(
            "Let us know what you are looking forward to using in our app.",
            comment: "Subtitle of the store creation profiler question about the features."
        )
    }
}
