import Foundation

/// Renders receipt data into a plain-text body for thermal (text-only) printing.
///
/// Pure and free of any printer SDK: it produces the human-readable receipt text that
/// `StarPrinterService` wraps into a StarXpand print command. The card/EMV block is included
/// only when card details are present, so cash and other payment methods render cleanly.
public struct StarReceiptTextBuilder {
    private let lineWidth: Int
    private let dateFormatter: DateFormatter

    public init(lineWidth: Int = Constants.defaultLineWidth,
                dateFormatter: DateFormatter = StarReceiptTextBuilder.makeDefaultDateFormatter()) {
        self.lineWidth = lineWidth
        self.dateFormatter = dateFormatter
    }

    public func makeReceiptText(content: ReceiptContent,
                                storeInformation: ReceiptStoreInformation,
                                cardDetails: CardPresentTransactionDetails?) -> String {
        var lines: [String] = []

        lines.append(contentsOf: headerLines(content: content, storeInformation: storeInformation))
        lines.append(separator)
        lines.append(contentsOf: paymentLines(content: content, cardDetails: cardDetails))
        lines.append(separator)
        lines.append(contentsOf: content.lineItems.map(itemLine))
        lines.append(separator)
        lines.append(contentsOf: content.cartTotals.map(totalLine))

        if let note = content.orderNote, note.isEmpty == false {
            lines.append(separator)
            lines.append(Localization.notes)
            lines.append(note)
        }

        if let emvBlock = emvLines(cardDetails: cardDetails) {
            lines.append(separator)
            lines.append(contentsOf: emvBlock)
        }

        if let policy = storeInformation.refundReturnsPolicy, policy.isEmpty == false {
            lines.append(separator)
            lines.append(policy)
        }

        return lines.joined(separator: "\n") + "\n"
    }
}

private extension StarReceiptTextBuilder {
    func headerLines(content: ReceiptContent, storeInformation: ReceiptStoreInformation) -> [String] {
        var lines: [String] = []
        if let storeName = storeInformation.storeName ?? content.parameters.storeName, storeName.isEmpty == false {
            lines.append(centered(storeName))
        }
        [storeInformation.storeAddress, storeInformation.phone, storeInformation.email]
            .compactMap { $0 }
            .filter { $0.isEmpty == false }
            .forEach { lines.append(centered($0)) }
        return lines
    }

    func paymentLines(content: ReceiptContent, cardDetails: CardPresentTransactionDetails?) -> [String] {
        var lines: [String] = [
            Localization.datePaid,
            dateFormatter.string(from: content.parameters.date)
        ]

        if let orderID = content.parameters.orderID {
            lines.append(String.localizedStringWithFormat(Localization.orderNumber, String(orderID)))
        }

        if let cardDetails {
            let brand = cardDetails.brand.rawValue.capitalized
            lines.append(Localization.paymentMethod)
            lines.append(String.localizedStringWithFormat(Localization.cardBrandAndLast4, brand, cardDetails.last4))
        }

        return lines
    }

    func emvLines(cardDetails: CardPresentTransactionDetails?) -> [String]? {
        guard let receipt = cardDetails?.receipt else {
            return nil
        }

        var lines = [
            String.localizedStringWithFormat(Localization.applicationName, receipt.applicationPreferredName),
            String.localizedStringWithFormat(Localization.aid, receipt.dedicatedFileName)
        ]
        if let accountType = receipt.accountType, accountType.isEmpty == false {
            lines.append(String.localizedStringWithFormat(Localization.accountType, accountType))
        }
        return lines
    }

    func itemLine(_ item: ReceiptLineItem) -> String {
        twoColumns(left: String.localizedStringWithFormat(Localization.itemTitleAndQuantity, item.title, item.quantity),
                   right: item.amount)
    }

    func totalLine(_ total: ReceiptTotalLine) -> String {
        twoColumns(left: total.description, right: total.amount)
    }

    /// Lays `left` and `right` on a single line, padding the gap so `right` ends at `lineWidth`.
    func twoColumns(left: String, right: String) -> String {
        let padding = max(lineWidth - left.count - right.count, 1)
        return left + String(repeating: " ", count: padding) + right
    }

    func centered(_ text: String) -> String {
        let padding = max((lineWidth - text.count) / 2, 0)
        return String(repeating: " ", count: padding) + text
    }

    var separator: String {
        String(repeating: "-", count: lineWidth)
    }
}

public extension StarReceiptTextBuilder {
    enum Constants {
        /// Characters per line for an 80mm thermal roll at the default font.
        public static let defaultLineWidth = 48
    }

    static func makeDefaultDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

private extension StarReceiptTextBuilder {
    enum Localization {
        static let datePaid = NSLocalizedString(
            "hardware.receipt.datePaid",
            value: "Date Paid",
            comment: "Label above the payment date on a printed receipt.")

        static let orderNumber = NSLocalizedString(
            "hardware.receipt.orderNumber",
            value: "Order #%1$@",
            comment: "Order number line on a printed receipt. %1$@ is the order ID.")

        static let paymentMethod = NSLocalizedString(
            "hardware.receipt.paymentMethod",
            value: "Payment Method",
            comment: "Label above the card payment method on a printed receipt.")

        static let cardBrandAndLast4 = NSLocalizedString(
            "hardware.receipt.cardBrandAndLast4",
            value: "%1$@ - %2$@",
            comment: "Card payment method on a printed receipt. %1$@ is the card brand, %2$@ is the last 4 digits.")

        static let notes = NSLocalizedString(
            "hardware.receipt.notes",
            value: "Notes",
            comment: "Label above the order note on a printed receipt.")

        static let applicationName = NSLocalizedString(
            "hardware.receipt.applicationName",
            value: "Application Name: %1$@",
            comment: "EMV application name (card scheme app) line on a printed receipt. %1$@ is the application name.")

        static let aid = NSLocalizedString(
            "hardware.receipt.aid",
            value: "AID: %1$@",
            comment: "EMV Application Identifier line on a printed receipt. %1$@ is the AID value.")

        static let accountType = NSLocalizedString(
            "hardware.receipt.accountType",
            value: "Account Type: %1$@",
            comment: "EMV account type line on a printed receipt. %1$@ is the account type.")

        static let itemTitleAndQuantity = NSLocalizedString(
            "hardware.receipt.itemTitleAndQuantity",
            value: "%1$@ x%2$@",
            comment: "A purchased line item on a printed receipt. %1$@ is the item title, %2$@ is the quantity.")
    }
}
