import Foundation
import Testing
@testable import WooAIAssistant

struct ToolPreviewsTests {
    @Test(arguments: [
        (OrdersUpdateTool.name,
         #"{"id":42,"status":"processing"}"#,
         "Set order #42 to processing (emails the customer)"),
        (OrdersBulkUpdateTool.name,
         #"{"ids":[1,2,3,4,5],"patch":{"status":"completed"}}"#,
         "Update 5 orders: status -> completed (emails customers)"),
        (ProductsUpdateTool.name,
         #"{"id":7,"regular_price":"24.99","stock_quantity":100}"#,
         "Update product #7: price -> 24.99, stock -> 100"),
        (ProductsBulkUpdateTool.name,
         #"{"ids":[10],"patch":{"status":"draft"}}"#,
         "Update 1 product: status -> draft"),
        (ProductVariationsUpdateTool.name,
         #"{"product_id":7,"id":15,"regular_price":"19.99"}"#,
         "Update variation #15 of product #7: price -> 19.99")
    ])
    func test_defaultBuilder_when_known_tool_then_returns_readable_preview(
        toolName: String,
        argumentsJSON: String,
        expected: String
    ) {
        // When
        let preview = ToolPreviews.defaultBuilder(toolName, argumentsJSON)

        // Then
        #expect(preview == expected)
    }

    @Test
    func test_genericPreview_when_unknown_tool_name_then_returns_truncated_args() {
        // Given
        let longArgs = String(repeating: "a", count: 100)

        // When
        let preview = ToolPreviews.defaultBuilder("future_unknown_tool", longArgs)

        // Then
        let expectedTruncated = String(repeating: "a", count: 80) + "..."
        #expect(preview == "future_unknown_tool \(expectedTruncated)")
    }
}
