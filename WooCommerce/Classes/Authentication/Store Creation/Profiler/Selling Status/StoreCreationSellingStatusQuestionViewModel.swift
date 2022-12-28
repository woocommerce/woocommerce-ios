import Combine
import Foundation

/// View model for `StoreCreationSellingStatusQuestionView`, an optional profiler question about store selling status in the store creation flow.
@MainActor
final class StoreCreationSellingStatusQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    /// Selling status options.
    /// https://github.com/Automattic/woocommerce.com/blob/trunk/themes/woo/start/config/options.json
    enum SellingStatus: Equatable {
        /// Just starting my business.
        case justStarting
        /// Already selling, but not online.
        case alreadySellingButNotOnline
        /// Already selling online.
        case alreadySellingOnline
    }

    let topHeader: String

    let title: String = Localization.title

    let subtitle: String = Localization.subtitle

    /// Question content.
    /// TODO: 8376 - update values when API is ready.
    let sellingStatuses: [SellingStatus] = [.justStarting, .alreadySellingButNotOnline, .alreadySellingOnline]

    @Published private(set) var selectedStatus: SellingStatus?

    private let onContinue: () -> Void
    private let onSkip: () -> Void

    init(storeName: String,
         onContinue: @escaping () -> Void,
         onSkip: @escaping () -> Void) {
        self.topHeader = storeName
        self.onContinue = onContinue
        self.onSkip = onSkip
    }
}

extension StoreCreationSellingStatusQuestionViewModel: OptionalStoreCreationProfilerQuestionViewModel {
    func continueButtonTapped() async {
        guard selectedStatus != nil else {
            return onSkip()
        }
        onContinue()
    }

    func skipButtonTapped() {
        onSkip()
    }
}

extension StoreCreationSellingStatusQuestionViewModel {
    /// Called when a selling status option is selected.
    func selectStatus(_ status: SellingStatus) {
        selectedStatus = status
    }
}

extension StoreCreationSellingStatusQuestionViewModel.SellingStatus {
    var description: String {
        switch self {
        case .justStarting:
            return NSLocalizedString(
                "I am just starting to sell",
                comment: "Option in the store creation selling status question."
            )
        case .alreadySellingButNotOnline:
            return NSLocalizedString(
                "I am selling offline",
                comment: "Option in the store creation selling status question."
            )
        case .alreadySellingOnline:
            return NSLocalizedString(
                "I am already selling online",
                comment: "Option in the store creation selling status question."
            )
        }
    }
}

private extension StoreCreationSellingStatusQuestionViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "Where are you on your commerce journey?",
            comment: "Title of the store creation profiler question about the store selling status."
        )
        static let subtitle = NSLocalizedString(
            "To speed things up, we’ll tailor your WooCommerce experience for you based on your response.",
            comment: "Subtitle of the store creation profiler question about the store selling status."
        )
    }
}
