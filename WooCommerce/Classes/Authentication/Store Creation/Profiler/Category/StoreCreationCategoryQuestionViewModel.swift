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
final class StoreCreationCategoryQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    typealias Answer = StoreCreationCategoryAnswer

    let topHeader: String = Localization.header

    let title: String = Localization.title

    let subtitle: String = Localization.subtitle

    /// Question content.
    @Published private(set) var selectedCategory: Category?

    private let onContinue: (Answer) -> Void
    private let onSkip: () -> Void

    init(onContinue: @escaping (Answer) -> Void,
         onSkip: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onSkip = onSkip
    }
}

extension StoreCreationCategoryQuestionViewModel: OptionalStoreCreationProfilerQuestionViewModel {
    func continueButtonTapped() {
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
        static let header = NSLocalizedString(
            "About your store",
            comment: "Header of the store creation profiler question about the store category."
        )
        static let title = NSLocalizedString(
            "What do you plan to sell in your store?",
            comment: "Title of the store creation profiler question about the store category."
        )
        static let subtitle = NSLocalizedString(
            "Choose a category that defines your business the best.",
            comment: "Subtitle of the store creation profiler question about the store category."
        )
    }
}
