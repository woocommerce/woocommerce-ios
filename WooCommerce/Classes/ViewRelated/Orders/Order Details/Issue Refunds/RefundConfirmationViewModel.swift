import Foundation

final class RefundConfirmationViewModel {
    private(set) var sections: [Section]

    init() {
        sections = [
            Section(
                title: nil,
                rows: [
                    TwoColumnRow(title: Localization.previouslyRefunded, value: "$0.01", isHeadline: false),
                    TwoColumnRow(title: Localization.refundAmount, value: "$1.23", isHeadline: true)
                ]
            ),
            Section(
                title: Localization.refundVia,
                rows: []
            )
        ]
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
        let isHeadline: Bool
    }
}

// MARK: - Localization

private extension RefundConfirmationViewModel {
    enum Localization {
        static let previouslyRefunded = NSLocalizedString("Previously Refunded", comment: "")
        static let refundAmount = NSLocalizedString("Refund Amount", comment: "")
        static let refundVia = NSLocalizedString("Refund Via", comment: "")
    }
}
