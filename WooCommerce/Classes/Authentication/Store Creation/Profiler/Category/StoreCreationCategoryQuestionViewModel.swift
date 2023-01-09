import Combine
import Foundation

/// View model for `StoreCreationCategoryQuestionView`, an optional profiler question about store category in the store creation flow.
@MainActor
final class StoreCreationCategoryQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    let topHeader: String

    let title: String = Localization.title

    let subtitle: String = Localization.subtitle

    /// Question content.
    /// TODO: 8376 - update values when API is ready.
    @Published private(set) var selectedCategory: Category?

    private let onContinue: (String) -> Void
    private let onSkip: () -> Void

    init(storeName: String,
         onContinue: @escaping (String) -> Void,
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

        onContinue(selectedCategory.name)
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
