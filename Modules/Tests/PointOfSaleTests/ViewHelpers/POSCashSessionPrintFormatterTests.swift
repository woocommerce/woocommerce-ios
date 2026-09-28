import Foundation
import Testing
import class WooFoundation.CurrencySettings
@testable import PointOfSale

struct POSCashSessionPrintFormatterTests {
    @Test func test_text_when_session_is_closed_then_includes_totals_movements_and_fits_receipt_width() {
        // Given
        let movement = POSCashSessionMovement(id: UUID(), kind: .payOut, amount: 7.25,
                                              date: Date(timeIntervalSince1970: 120), actor: "Alex",
                                              orderID: nil, note: String(repeating: "Cash adjustment note ", count: 5))
        let session = POSCashSession(id: 42, openedAt: Date(timeIntervalSince1970: 0), openedBy: "Sam", openingCash: 100,
                                     movements: [movement], closedAt: Date(timeIntervalSince1970: 240), closedBy: "Alex",
                                     countedCash: 180, closingNote: "Checked against till bag",
                                     totals: .init(cashSales: 95, cashRefunds: 12.5, paidIn: 10, paidOut: 7.25, expectedCash: 185.25),
                                     currency: "EUR", currencyPrecision: 2,
                                     drawerID: "Front counter register with a long location name")
        let money = POSCashSessionMoney(settings: CurrencySettings(), session: session)

        // When
        let text = POSCashSessionPrintFormatter.text(for: session, money: money)

        // Then
        #expect(text.contains("CASH SESSION CLOSE-OUT"))
        #expect(text.contains("Session #42"))
        #expect(text.contains("Opened:"))
        #expect(text.contains("Closed:"))
        #expect(text.contains("Expected in drawer"))
        #expect(text.contains("Cash in drawer"))
        #expect(text.contains("Difference"))
        #expect(text.contains("MOVEMENTS"))
        #expect(text.contains("Pay out"))
        #expect(text.contains("CLOSING NOTE"))
        #expect(text.split(separator: "\n").allSatisfy { $0.count <= 48 })
        #expect(text.hasSuffix("\n"))
    }
}
