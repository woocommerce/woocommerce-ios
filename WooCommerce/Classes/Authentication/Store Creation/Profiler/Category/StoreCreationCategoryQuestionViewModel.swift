import Combine
import Foundation

/// Necessary data from the answer of the store creation category question.
struct StoreCreationCategoryAnswer: Equatable {
    /// Display name of the selected category.
    let name: String
    /// Raw value of the category (industry) to be sent to the backend.
    let value: String
}

/// View model for `StoreCreationCategoryQuestionView`, an optional profiler question about store category in the store creation flow.
@MainActor
final class StoreCreationCategoryQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    typealias Answer = StoreCreationCategoryAnswer

    let topHeader: String

    let title: String = Localization.title

    let subtitle: String = Localization.subtitle

    /// Question content.
    @Published private(set) var selectedCategory: Category?

    private let onContinue: (Answer) -> Void
    private let onSkip: () -> Void

    init(storeName: String,
         onContinue: @escaping (Answer) -> Void,
         onSkip: @escaping () -> Void) {
        self.topHeader = storeName
        self.onContinue = onContinue
        self.onSkip = onSkip
    }
}

extension StoreCreationCategoryQuestionViewModel: OptionalStoreCreationProfilerQuestionViewModel {
    func continueButtonTapped() async {
        guard let selectedCategory else {
            return onSkip()
        }

        onContinue(.init(name: selectedCategory.name, value: selectedCategory.rawValue))
    }

    func skipButtonTapped() {
        onSkip()
    }
}

extension StoreCreationCategoryQuestionViewModel {
    func selectCategory(_ category: Category) {
        selectedCategory = category
    }
}

private extension StoreCreationCategoryQuestionViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "What’s your business about?",
            comment: "Title of the store creation profiler question about the store category."
        )
        static let subtitle = NSLocalizedString(
            "Choose a category that defines your business the best.",
            comment: "Subtitle of the store creation profiler question about the store category."
        )
    }
}
