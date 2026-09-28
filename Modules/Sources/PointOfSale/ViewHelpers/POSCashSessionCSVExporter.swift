import Foundation

/// A stable, spreadsheet-friendly close-out record. Amounts use a decimal point and dates use UTC,
/// so the file can be imported without relying on the device's locale.
struct POSCashSessionCSVExporter {
    static func csv(for session: POSCashSession) -> String {
        var rows: [[String]] = [["section", "item", "value", "date", "actor", "order_id", "refund_id", "note"]]

        rows.append(row("session", "id", String(session.id)))
        rows.append(row("session", "drawer_id", text(session.drawerID)))
        rows.append(row("session", "currency", text(session.currency)))
        rows.append(row("session", "opened_at", date(session.openedAt)))
        rows.append(row("session", "opened_by", text(session.openedBy)))
        rows.append(row("session", "closed_at", session.closedAt.map(date) ?? ""))
        rows.append(row("session", "closed_by", text(session.closedBy)))
        rows.append(row("session", "closing_note", text(session.closingNote)))

        rows.append(row("totals", "opening_cash", amount(session.openingCash)))
        rows.append(row("totals", "cash_sales", amount(session.cashSales)))
        rows.append(row("totals", "cash_refunds", amount(session.cashRefunds)))
        rows.append(row("totals", "paid_in", amount(session.totals?.paidIn ?? total(.payIn, in: session))))
        rows.append(row("totals", "paid_out", amount(session.totals?.paidOut ?? total(.payOut, in: session))))
        rows.append(row("totals", "expected_cash", amount(session.expectedCash)))
        rows.append(row("totals", "counted_cash", session.countedCash.map(amount) ?? ""))
        rows.append(row("totals", "difference", session.difference.map(amount) ?? ""))

        rows.append(activityRow("session_opened", amount: session.openingCash, date: session.openedAt, actor: session.openedBy))
        for movement in session.movements.sorted(by: { $0.date < $1.date }) {
            rows.append(activityRow(item(for: movement.kind), amount: movement.signedAmount,
                                    date: movement.date, actor: movement.actor, orderID: movement.orderID,
                                    refundID: movement.refundID, note: movement.note))
        }
        if let closedAt = session.closedAt {
            rows.append(activityRow("session_closed", amount: session.countedCash, date: closedAt,
                                    actor: session.closedBy ?? "", note: session.closingNote))
        }

        return rows.map { $0.map(escaped).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    static func writeFile(for session: POSCashSession) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("cash-session-export-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        let file = directory.appendingPathComponent("cash-session-\(session.id).csv")
        do {
            try csv(for: session).write(to: file, atomically: true, encoding: .utf8)
            return file
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    private static func row(_ section: String, _ item: String, _ value: String) -> [String] {
        [section, item, value, "", "", "", "", ""]
    }

    private static func activityRow(_ item: String, amount: Decimal?, date: Date, actor: String,
                                    orderID: Int64? = nil, refundID: Int64? = nil, note: String? = nil) -> [String] {
        ["activity", item, amount.map(Self.amount) ?? "", Self.date(date), text(actor),
         orderID.map { String($0) } ?? "", refundID.map { String($0) } ?? "", text(note)]
    }

    private static func item(for kind: POSCashSessionMovement.Kind) -> String {
        switch kind {
        case .cashSale: "cash_sale"
        case .cashRefund: "cash_refund"
        case .payIn: "pay_in"
        case .payOut: "pay_out"
        }
    }

    private static func total(_ kind: POSCashSessionMovement.Kind, in session: POSCashSession) -> Decimal {
        session.movements.filter { $0.kind == kind }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private static func amount(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    private static func date(_ value: Date) -> String {
        ISO8601DateFormatter().string(from: value)
    }

    /// Stops spreadsheet formulas in user-entered names, drawer labels, and notes.
    private static func text(_ value: String?) -> String {
        guard let value else { return "" }
        let first = value.drop(while: { $0.isWhitespace }).first
        if let first, "=+-@".contains(first) {
            return "'" + value
        }
        return value
    }

    private static func escaped(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\r" || $0 == "\n" }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
