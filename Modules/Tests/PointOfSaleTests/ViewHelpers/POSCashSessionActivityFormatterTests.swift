import Testing
@testable import PointOfSale

struct POSCashSessionActivityFormatterTests {
    @Test(arguments: [nil, "", " \n\t "] as [String?])
    func test_reference_and_note_when_note_is_missing_or_blank_then_shows_order_reference(note: String?) {
        // Given
        let orderID: Int64 = 1452

        // When
        let detail = POSCashSessionActivityFormatter.referenceAndNote(orderID: orderID, note: note)

        // Then
        #expect(detail == "Order #1452")
    }

    @Test func test_reference_and_note_when_both_exist_then_preserves_order_reference_and_note() {
        // Given
        let orderID: Int64 = 1452
        let note = " Returned duplicate item \n"

        // When
        let detail = POSCashSessionActivityFormatter.referenceAndNote(orderID: orderID, note: note)

        // Then
        #expect(detail == "Order #1452 · Returned duplicate item")
    }

    @Test func test_reference_and_note_when_manual_movement_has_no_order_then_shows_note() {
        // Given
        let note = " Change from bank "

        // When
        let detail = POSCashSessionActivityFormatter.referenceAndNote(orderID: nil, note: note)

        // Then
        #expect(detail == "Change from bank")
    }

    @Test(arguments: [nil, "", " \n\t "] as [String?])
    func test_reference_and_note_when_no_order_or_note_then_omits_detail(note: String?) {
        // Given
        let orderID: Int64? = nil

        // When
        let detail = POSCashSessionActivityFormatter.referenceAndNote(orderID: orderID, note: note)

        // Then
        #expect(detail == nil)
    }
}
