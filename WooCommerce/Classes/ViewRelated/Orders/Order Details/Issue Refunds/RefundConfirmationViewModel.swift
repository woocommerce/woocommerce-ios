import Foundation

final class RefundConfirmationViewModel {
    private(set) var sections: [Section]

    init() {
        sections = [Section(title: nil, rows: [
            TwoColumnRow(title: Localization.previouslyRefunded, value: "$0.01"),
            TwoColumnRow(title: Localization.refundAmount, value: "$1.23")
        ])]
    }
}

// MARK: - Sections and Rows

protocol RefundConfirmationViewModelRow {

}

extension RefundConfirmationViewModel {
    struct Section {
        let title: String?
        let rows: [RefundConfirmationViewModelRow]
    }

    struct TwoColumnRow: RefundConfirmationViewModelRow {
        let title: String
        let value: String
    }
}

// MARK: - Localization

private extension RefundConfirmationViewModel {
    enum Localization {
        static let previouslyRefunded = NSLocalizedString("Previously Refunded", comment: "")
        static let refundAmount = NSLocalizedString("Refund Amount", comment: "")
    }
}
