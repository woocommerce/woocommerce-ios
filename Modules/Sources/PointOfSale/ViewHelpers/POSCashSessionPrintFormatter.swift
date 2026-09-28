import Foundation
import struct Yosemite.ReceiptTextRenderer

/// Formats a closed cash session for the same 80 mm, 48-column thermal paper as POS receipts.
struct POSCashSessionPrintFormatter {
    private static let width = ReceiptTextRenderer.Constants.defaultLineWidth
    private static let rule = String(repeating: "-", count: width)

    static func text(for session: POSCashSession, money: POSCashSessionMoney) -> String {
        var lines = [Localization.title,
                     String.localizedStringWithFormat(Localization.sessionNumber, String(session.id))]

        if let drawer = session.drawerID, !drawer.isEmpty {
            lines += wrap(String.localizedStringWithFormat(Localization.drawer, drawer))
        }
        lines += [rule]
        lines += wrap(String.localizedStringWithFormat(Localization.opened, date(session.openedAt), session.openedBy))
        if let closedAt = session.closedAt {
            lines += wrap(String.localizedStringWithFormat(Localization.closed, date(closedAt), session.closedBy ?? session.openedBy))
        }
        lines += [rule, Localization.summary]
        lines += columns(Localization.startingCash, money.format(session.openingCash))
        lines += columns(Localization.cashSales, money.format(session.cashSales))
        lines += columns(Localization.cashRefunds, money.format(-session.cashRefunds))
        lines += columns(Localization.paidInOut, money.formatSigned(session.paidInOut))
        lines += columns(Localization.expectedCash, money.format(session.expectedCash))
        if let countedCash = session.countedCash {
            lines += columns(Localization.countedCash, money.format(countedCash))
        }
        if let difference = session.difference {
            lines += columns(Localization.difference, money.formatSigned(difference))
        }

        if !session.movements.isEmpty {
            lines += [rule, Localization.movements]
            for movement in session.movements.sorted(by: { $0.date < $1.date }) {
                lines += columns(title(for: movement.kind), money.formatSigned(movement.signedAmount))
                lines += wrap(String.localizedStringWithFormat(Localization.movementDetail,
                                                               date(movement.date), movement.actor))
                if let orderID = movement.orderID {
                    lines += wrap(String.localizedStringWithFormat(Localization.order, String(orderID)))
                }
                if let refundID = movement.refundID {
                    lines += wrap(String.localizedStringWithFormat(Localization.refund, String(refundID)))
                }
                if let note = movement.note, !note.isEmpty {
                    lines += wrap(note)
                }
            }
        }

        if let note = session.closingNote, !note.isEmpty {
            lines += [rule, Localization.closingNote]
            lines += wrap(note)
        }
        return (lines + [rule]).joined(separator: "\n") + "\n"
    }

    private static func date(_ value: Date) -> String {
        value.formatted(date: .abbreviated, time: .shortened)
    }

    private static func title(for kind: POSCashSessionMovement.Kind) -> String {
        switch kind {
        case .cashSale: Localization.cashSale
        case .cashRefund: Localization.cashRefund
        case .payIn: Localization.payIn
        case .payOut: Localization.payOut
        }
    }

    /// Keeps each amount intact and right aligned, even when the label wraps.
    private static func columns(_ label: String, _ amount: String) -> [String] {
        var labelLines = wrap(label)
        let last = labelLines.removeLast()
        if last.count + amount.count + 1 <= width {
            labelLines.append(last + String(repeating: " ", count: width - last.count - amount.count) + amount)
        } else {
            labelLines.append(last)
            labelLines += amount.count <= width ? [String(repeating: " ", count: width - amount.count) + amount] : wrap(amount)
        }
        return labelLines
    }

    private static func wrap(_ text: String) -> [String] {
        var lines: [String] = []
        for paragraph in text.split(whereSeparator: \.isNewline) {
            var current = ""
            for wordSlice in paragraph.split(whereSeparator: \.isWhitespace) {
                var word = String(wordSlice)
                while word.count > width {
                    if !current.isEmpty {
                        lines.append(current)
                        current = ""
                    }
                    lines.append(String(word.prefix(width)))
                    word.removeFirst(width)
                }
                if current.isEmpty {
                    current = word
                } else if current.count + word.count + 1 <= width {
                    current += " " + word
                } else {
                    lines.append(current)
                    current = word
                }
            }
            if !current.isEmpty {
                lines.append(current)
            }
        }
        return lines.isEmpty ? [""] : lines
    }
}

private extension POSCashSessionPrintFormatter {
    enum Localization {
        static let title = NSLocalizedString("pos.cashSession.print.title", value: "CASH SESSION CLOSE-OUT", comment: "Printed cash session title")
        static let sessionNumber = NSLocalizedString("pos.cashSession.print.number", value: "Session #%1$@", comment: "Printed session ID")
        static let drawer = NSLocalizedString("pos.cashSession.print.drawer", value: "Drawer: %1$@", comment: "Printed drawer name")
        static let opened = NSLocalizedString("pos.cashSession.print.opened", value: "Opened: %1$@ by %2$@", comment: "Printed opening date and staff")
        static let closed = NSLocalizedString("pos.cashSession.print.closed", value: "Closed: %1$@ by %2$@", comment: "Printed closing date and staff")
        static let summary = NSLocalizedString("pos.cashSession.print.summary", value: "CASH SUMMARY", comment: "Printed cash summary heading")
        static let startingCash = NSLocalizedString("pos.cashSession.print.startingCash", value: "Starting cash", comment: "Printed starting cash")
        static let cashSales = NSLocalizedString("pos.cashSession.print.cashSales", value: "Cash sales", comment: "Printed cash sales")
        static let cashRefunds = NSLocalizedString("pos.cashSession.print.cashRefunds", value: "Cash refunds", comment: "Printed cash refunds")
        static let paidInOut = NSLocalizedString("pos.cashSession.print.paidInOut", value: "Paid in/out", comment: "Printed cash adjustments")
        static let expectedCash = NSLocalizedString("pos.cashSession.print.expectedCash", value: "Expected in drawer", comment: "Printed expected cash")
        static let countedCash = NSLocalizedString("pos.cashSession.print.countedCash", value: "Cash in drawer", comment: "Printed counted cash")
        static let difference = NSLocalizedString("pos.cashSession.print.difference", value: "Difference", comment: "Printed cash difference")
        static let movements = NSLocalizedString("pos.cashSession.print.movements", value: "MOVEMENTS", comment: "Printed cash movements heading")
        static let movementDetail = NSLocalizedString("pos.cashSession.print.movementDetail", value: "%1$@ by %2$@",
                                                    comment: "Printed movement date and staff")
        static let order = NSLocalizedString("pos.cashSession.print.order", value: "Order #%1$@", comment: "Printed movement order reference")
        static let refund = NSLocalizedString("pos.cashSession.print.refund", value: "Refund #%1$@", comment: "Printed movement refund reference")
        static let cashSale = NSLocalizedString("pos.cashSession.print.cashSale", value: "Cash sale", comment: "Printed cash sale")
        static let cashRefund = NSLocalizedString("pos.cashSession.print.cashRefund", value: "Cash refund", comment: "Printed cash refund")
        static let payIn = NSLocalizedString("pos.cashSession.print.payIn", value: "Pay in", comment: "Printed pay in")
        static let payOut = NSLocalizedString("pos.cashSession.print.payOut", value: "Pay out", comment: "Printed pay out")
        static let closingNote = NSLocalizedString("pos.cashSession.print.closingNote", value: "CLOSING NOTE", comment: "Printed closing note heading")
    }
}
