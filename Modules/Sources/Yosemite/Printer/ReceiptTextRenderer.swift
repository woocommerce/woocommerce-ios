import Foundation
import Hardware

/// Renders receipt data into a plain-text body for thermal (text-only) printing.
///
/// Pure and printer-agnostic: it produces the human-readable receipt text that a printer
/// backend wraps into its own print command. The card/EMV block is included only when card
/// details are present, so cash and other payment methods render cleanly.
public struct ReceiptTextRenderer {
    private let lineWidth: Int
    private let dateFormatter: DateFormatter

    public init(lineWidth: Int = Constants.defaultLineWidth,
                dateFormatter: DateFormatter = ReceiptTextRenderer.makeDefaultDateFormatter()) {
        precondition(lineWidth > 0, "lineWidth must be positive; the wrapping logic assumes at least one column.")
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
        lines.append(contentsOf: content.lineItems.flatMap(itemLine))
        lines.append(separator)
        lines.append(contentsOf: content.cartTotals.flatMap(totalLine))

        if let note = content.orderNote, note.isEmpty == false {
            lines.append(separator)
            lines.append(Localization.notes)
            lines.append(contentsOf: wrap(note))
        }

        if let emvBlock = emvLines(cardDetails: cardDetails) {
            lines.append(separator)
            lines.append(contentsOf: emvBlock)
        }

        if let policy = storeInformation.refundReturnsPolicy, policy.isEmpty == false {
            lines.append(separator)
            lines.append(contentsOf: wrap(policy))
        }

        return lines.joined(separator: "\n") + "\n"
    }
}

private extension ReceiptTextRenderer {
    func headerLines(content: ReceiptContent, storeInformation: ReceiptStoreInformation) -> [String] {
        var lines: [String] = []
        if let storeName = storeInformation.storeName ?? content.parameters.storeName, storeName.isEmpty == false {
            lines.append(contentsOf: centeredLines(storeName))
        }
        [storeInformation.storeAddress, storeInformation.phone, storeInformation.email]
            .compactMap { $0 }
            .filter { $0.isEmpty == false }
            .forEach { lines.append(contentsOf: centeredLines($0)) }
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
            lines.append(Localization.paymentMethod)
            let brand = cardDetails.brand.displayName
            if brand.isEmpty {
                lines.append(cardDetails.last4)
            } else {
                lines.append(String.localizedStringWithFormat(Localization.cardBrandAndLast4, brand, cardDetails.last4))
            }
        }

        return lines.flatMap(wrap)
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
        return lines.flatMap(wrap)
    }

    func itemLine(_ item: ReceiptLineItem) -> [String] {
        twoColumns(left: itemTitle(item), right: item.amount)
    }

    func totalLine(_ total: ReceiptTotalLine) -> [String] {
        twoColumns(left: total.description, right: total.amount)
    }

    /// Builds the left column for a line item: title plus quantity, with any product attributes
    /// (e.g. variations) appended after the title to match the AirPrint receipt format.
    func itemTitle(_ item: ReceiptLineItem) -> String {
        var title = item.title
        let variations = item.attributes
            .map { "\($0.name) \($0.value)".trimmingCharacters(in: .whitespaces) }
            .filter { $0.isEmpty == false }
            .joined(separator: ", ")
        if variations.isEmpty == false {
            title = String.localizedStringWithFormat(Localization.itemTitleWithAttributes, title, variations)
        }
        return String.localizedStringWithFormat(Localization.itemTitleAndQuantity, title, item.quantity)
    }

    /// Lays `left` and `right` across one or more lines, none wider than `lineWidth`.
    ///
    /// When both fit together, `right` is padded so it ends at `lineWidth`. Otherwise `left` is
    /// word-wrapped and `right` is appended to the last line if it fits there, or right-aligned on
    /// its own line. This keeps the amount column intact instead of letting the printer wrap or
    /// truncate it unpredictably.
    func twoColumns(left: String, right: String) -> [String] {
        if left.count + right.count + 1 <= lineWidth {
            return [left + String(repeating: " ", count: lineWidth - left.count - right.count) + right]
        }

        var lines = wrap(left)
        let last = lines.popLast() ?? ""
        if last.count + right.count + 1 <= lineWidth {
            lines.append(last + String(repeating: " ", count: lineWidth - last.count - right.count) + right)
        } else {
            if last.isEmpty == false {
                lines.append(last)
            }
            // A right column wider than the roll can't be right-aligned on one line, so wrap it too.
            if right.count <= lineWidth {
                lines.append(rightAligned(right))
            } else {
                lines.append(contentsOf: wrap(right))
            }
        }
        return lines
    }

    /// Greedily word-wraps `text` into lines no wider than `lineWidth`, hard-splitting any single
    /// word that is itself wider than `lineWidth`. Always returns at least one (possibly empty) line.
    func wrap(_ text: String) -> [String] {
        var lines: [String] = []
        var current = ""

        for rawWord in text.split(separator: " ", omittingEmptySubsequences: true) {
            var word = String(rawWord)
            while word.count > lineWidth {
                if current.isEmpty == false {
                    lines.append(current)
                    current = ""
                }
                lines.append(String(word.prefix(lineWidth)))
                word.removeFirst(lineWidth)
            }
            if current.isEmpty {
                current = word
            } else if current.count + 1 + word.count <= lineWidth {
                current += " " + word
            } else {
                lines.append(current)
                current = word
            }
        }
        if current.isEmpty == false {
            lines.append(current)
        }
        return lines.isEmpty ? [""] : lines
    }

    func centeredLines(_ text: String) -> [String] {
        wrap(text).map(centered)
    }

    func centered(_ text: String) -> String {
        let padding = max((lineWidth - text.count) / 2, 0)
        return String(repeating: " ", count: padding) + text
    }

    func rightAligned(_ text: String) -> String {
        String(repeating: " ", count: max(lineWidth - text.count, 0)) + text
    }

    var separator: String {
        String(repeating: "-", count: lineWidth)
    }
}

public extension ReceiptTextRenderer {
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

private extension ReceiptTextRenderer {
    enum Localization {
        static let datePaid = NSLocalizedString(
            "receipt.datePaid",
            value: "Date Paid",
            comment: "Label above the payment date on a printed receipt.")

        static let orderNumber = NSLocalizedString(
            "receipt.orderNumber",
            value: "Order #%1$@",
            comment: "Order number line on a printed receipt. %1$@ is the order ID.")

        static let paymentMethod = NSLocalizedString(
            "receipt.paymentMethod",
            value: "Payment Method",
            comment: "Label above the card payment method on a printed receipt.")

        static let cardBrandAndLast4 = NSLocalizedString(
            "receipt.cardBrandAndLast4",
            value: "%1$@ - %2$@",
            comment: "Card payment method on a printed receipt. %1$@ is the card brand, %2$@ is the last 4 digits.")

        static let notes = NSLocalizedString(
            "receipt.notes",
            value: "Notes",
            comment: "Label above the order note on a printed receipt.")

        static let applicationName = NSLocalizedString(
            "receipt.applicationName",
            value: "Application Name: %1$@",
            comment: "EMV application name (card scheme app) line on a printed receipt. %1$@ is the application name.")

        static let aid = NSLocalizedString(
            "receipt.aid",
            value: "AID: %1$@",
            comment: "EMV Application Identifier line on a printed receipt. %1$@ is the AID value.")

        static let accountType = NSLocalizedString(
            "receipt.accountType",
            value: "Account Type: %1$@",
            comment: "EMV account type line on a printed receipt. %1$@ is the account type.")

        static let itemTitleAndQuantity = NSLocalizedString(
            "receipt.itemTitleAndQuantity",
            value: "%1$@ x%2$@",
            comment: "A purchased line item on a printed receipt. %1$@ is the item title, %2$@ is the quantity.")

        static let itemTitleWithAttributes = NSLocalizedString(
            "receipt.itemTitleWithAttributes",
            value: "%1$@. %2$@",
            comment: "A line item title with its product attributes on a printed receipt. "
                + "%1$@ is the item title, %2$@ is the comma-separated attributes (e.g. variations).")
    }
}
