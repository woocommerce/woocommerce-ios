import Foundation

enum POSCashSessionActivityFormatter {
    static func referenceAndNote(orderID: Int64?, note: String?) -> String? {
        let reference = orderID.map { String.localizedStringWithFormat(Localization.orderNumber, String($0)) }
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let nonEmptyNote = trimmedNote.flatMap { $0.isEmpty ? nil : $0 }

        if let reference, let nonEmptyNote {
            return String.localizedStringWithFormat(Localization.orderAndNote, reference, nonEmptyNote)
        }
        return reference ?? nonEmptyNote
    }
}

private extension POSCashSessionActivityFormatter {
    enum Localization {
        static let orderNumber = NSLocalizedString("pos.cashSession.activity.orderNumber", value: "Order #%1$@", comment: "Order reference in cash activity")
        static let orderAndNote = NSLocalizedString("pos.cashSession.activity.orderAndNote", value: "%1$@ · %2$@",
                                                    comment: "Cash activity details. %1$@ is the order reference and %2$@ is the movement note.")
    }
}
