import Foundation
import Testing
@testable import WooAIAssistant

struct ToolPreviewsTests {
    @Test
    func test_ordersUpdate_preview_when_status_set_to_processing_then_includes_email_note() {
        // Given
        let arguments = #"{"id":42,"status":"processing"}"#

        // When
        let preview = ToolPreviews.defaultBuilder(OrdersUpdateTool.name, arguments)

        // Then
        #expect(preview == "Set order #42 to processing (emails the customer)")
    }

    @Test
    func test_ordersBulkUpdate_preview_when_status_change_for_many_then_pluralizes_and_summarizes() {
        // Given
        let arguments = #"{"ids":[1,2,3,4,5],"patch":{"status":"completed"}}"#

        // When
        let preview = ToolPreviews.defaultBuilder(OrdersBulkUpdateTool.name, arguments)

        // Then
        #expect(preview == "Update 5 orders: status -> completed")
    }

    @Test
    func test_productsUpdate_preview_when_price_and_stock_set_then_lists_changes_in_order() {
        // Given
        let arguments = #"{"id":7,"regular_price":"24.99","stock_quantity":100}"#

        // When
        let preview = ToolPreviews.defaultBuilder(ProductsUpdateTool.name, arguments)

        // Then
        #expect(preview == "Update product #7: price -> $24.99, stock -> 100")
    }

    @Test
    func test_productsBulkUpdate_preview_when_one_id_then_uses_singular_noun() {
        // Given
        let arguments = #"{"ids":[10],"patch":{"status":"draft"}}"#

        // When
        let preview = ToolPreviews.defaultBuilder(ProductsBulkUpdateTool.name, arguments)

        // Then
        #expect(preview == "Update 1 product: status -> draft")
    }

    @Test
    func test_productVariationsUpdate_preview_when_price_set_then_names_variation_and_parent() {
        // Given
        let arguments = #"{"product_id":7,"id":15,"regular_price":"19.99"}"#

        // When
        let preview = ToolPreviews.defaultBuilder(ProductVariationsUpdateTool.name, arguments)

        // Then
        #expect(preview == "Update variation #15 of product #7: price -> $19.99")
    }

    @Test
    func test_genericPreview_when_unknown_tool_name_then_returns_truncated_args() {
        // Given a tool name not in the routing table and arguments longer than 80 chars
        let longArgs = String(repeating: "a", count: 100)

        // When
        let preview = ToolPreviews.defaultBuilder("future_unknown_tool", longArgs)

        // Then
        let expectedTruncated = String(repeating: "a", count: 80) + "..."
        #expect(preview == "future_unknown_tool \(expectedTruncated)")
    }
}
