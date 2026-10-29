import Testing
@testable import PointOfSale

struct POSRefundReviewLocalizationTests {
    @Test(arguments: [(1, "Items subtotal (1 item)"), (2, "Items subtotal (2 items)")])
    func test_items_subtotal_label_when_count_changes_then_uses_correct_english_form(count: Int, expected: String) {
        // When
        let label = POSRefundSubtotalLabel.make(count)

        // Then
        #expect(label == expected)
    }
}
