import Foundation
import Testing
@testable import PointOfSale

struct POSCashSessionCSVExporterTests {
    @Test func test_csv_when_session_is_closed_then_includes_server_totals_and_all_activity() {
        // Given
        let session = sampleSession()

        // When
        let csv = POSCashSessionCSVExporter.csv(for: session)

        // Then
        #expect(csv.hasPrefix("section,item,value,date,actor,order_id,refund_id,note\r\n"))
        #expect(csv.contains("session,id,42,,,,,\r\n"))
        #expect(csv.contains("session,drawer_id,'+Register,,,,,\r\n"))
        #expect(csv.contains("session,opened_at,1970-01-01T00:00:00Z,,,,,\r\n"))
        #expect(csv.contains("totals,cash_sales,95,,,,,\r\n"))
        #expect(csv.contains("totals,cash_refunds,12.5,,,,,\r\n"))
        #expect(csv.contains("totals,paid_in,10,,,,,\r\n"))
        #expect(csv.contains("totals,paid_out,7.25,,,,,\r\n"))
        #expect(csv.contains("totals,expected_cash,185.25,,,,,\r\n"))
        #expect(csv.contains("totals,difference,-5.25,,,,,\r\n"))
        #expect(csv.contains("activity,cash_sale,45,1970-01-01T00:01:00Z,Alex,301,,\r\n"))
        #expect(csv.contains("activity,cash_refund,-12.5,1970-01-01T00:02:00Z,Alex,301,509,\r\n"))
        #expect(csv.contains("activity,pay_out,-7.25,1970-01-01T00:03:00Z,Alex,,,"))
        #expect(csv.contains("activity,session_closed,180,1970-01-01T00:04:00Z,Alex,,,"))
    }

    @Test func test_csv_when_user_text_contains_formula_and_delimiters_then_quotes_and_prefixes_it() {
        // Given
        let session = sampleSession()

        // When
        let csv = POSCashSessionCSVExporter.csv(for: session)

        // Then
        #expect(csv.contains("session,opened_by,'=SUM(1;1),,,,,\r\n"))
        #expect(csv.contains("\"'=HYPERLINK(\"\"x\"\",\"\"y\"\"),\r\nnext\""))
    }

    @Test func test_write_file_when_session_is_closed_then_creates_a_csv_attachment() throws {
        // Given
        let session = sampleSession()

        // When
        let file = try POSCashSessionCSVExporter.writeFile(for: session)
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }

        // Then
        #expect(file.lastPathComponent == "cash-session-42.csv")
        #expect(try String(contentsOf: file, encoding: .utf8) == POSCashSessionCSVExporter.csv(for: session))
    }

    private func sampleSession() -> POSCashSession {
        let movements: [POSCashSessionMovement] = [
            .init(id: UUID(), kind: .cashSale, amount: 45, date: Date(timeIntervalSince1970: 60), actor: "Alex", orderID: 301, note: nil),
            .init(id: UUID(), kind: .cashRefund, amount: Decimal(string: "12.5") ?? 0,
                  date: Date(timeIntervalSince1970: 120), actor: "Alex", orderID: 301, refundID: 509, note: nil),
            .init(id: UUID(), kind: .payOut, amount: Decimal(string: "7.25") ?? 0,
                  date: Date(timeIntervalSince1970: 180), actor: "Alex", orderID: nil,
                  note: "=HYPERLINK(\"x\",\"y\"),\r\nnext")
        ]
        return POSCashSession(id: 42, openedAt: Date(timeIntervalSince1970: 0), openedBy: "=SUM(1;1)", openingCash: 100,
                              movements: movements, closedAt: Date(timeIntervalSince1970: 240), closedBy: "Alex", countedCash: 180,
                              closingNote: "Balanced after recount", totals: .init(cashSales: 95, cashRefunds: Decimal(string: "12.5") ?? 0,
                                                                                   paidIn: 10, paidOut: Decimal(string: "7.25") ?? 0,
                                                                                   expectedCash: Decimal(string: "185.25") ?? 0),
                              currency: "EUR", currencyPrecision: 2, drawerID: "+Register")
    }
}
