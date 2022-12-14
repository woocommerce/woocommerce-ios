import Combine
import Foundation

/// View model for `StoreCreationCategoryQuestionView`, an optional profiler question about store category in the store creation flow.
@MainActor
final class StoreCreationCategoryQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    /// Contains necessary information about a category.
    struct Category: Equatable {
        /// Display name for the category.
        let name: String
        /// Value that is sent to the API.
        let value: String
    }

    let topHeader: String

    let title: String = Localization.title

    let subtitle: String = Localization.subtitle

    /// Question content.
    /// TODO: 8376 - update values when API is ready.
    let categories: [Category] = [
        .init(name: NSLocalizedString("Art & Photography",
                                      comment: "Option in the store creation category question."),
              value: ""),
        .init(name: NSLocalizedString("Books & Magazines",
                                      comment: "Option in the store creation category question."),
              value: ""),
        .init(name: NSLocalizedString("Electronics and Software",
                                      comment: "Option in the store creation category question."),
              value: ""),
        .init(name: NSLocalizedString("Construction & Industrial",
                                      comment: "Option in the store creation category question."),
              value: ""),
        .init(name: NSLocalizedString("Design & Marketing",
                                      comment: "Option in the store creation category question."),
              value: ""),
        .init(name: NSLocalizedString("Fashion and Apparel",
                                      comment: "Option in the store creation category question."),
              value: ""),
        .init(name: NSLocalizedString("Food and Drink",
                                      comment: "Option in the store creation category question."),
              value: ""),
        .init(name: NSLocalizedString("Arts and Crafts",
                                      comment: "Option in the store creation category question."),
              value: ""),
        .init(name: NSLocalizedString("Health and Beauty",
                                      comment: "Option in the store creation category question."),
              value: ""),
        .init(name: NSLocalizedString("Pets Pet Care",
                                      comment: "Option in the store creation category question."),
              value: ""),
        .init(name: NSLocalizedString("Sports and Recreation",
                                      comment: "Option in the store creation category question."),
              value: "")
    ]

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
