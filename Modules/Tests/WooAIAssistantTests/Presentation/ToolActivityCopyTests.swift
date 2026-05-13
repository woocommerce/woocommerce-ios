import Testing
@testable import WooAIAssistant

struct ToolActivityCopyTests {

    @Test
    func test_label_when_orders_list_then_says_checking_orders() {
        // Given
        let toolName = "orders_list"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Checking orders")
    }

    @Test
    func test_label_when_orders_get_then_says_checking_orders() {
        // Given
        let toolName = "orders_get"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Checking orders")
    }

    @Test
    func test_label_when_orders_update_then_says_updating_orders() {
        // Given
        let toolName = "orders_update"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Updating orders")
    }

    @Test
    func test_label_when_orders_bulk_update_then_says_updating_orders() {
        // Given
        let toolName = "orders_bulk_update"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Updating orders")
    }

    @Test
    func test_label_when_products_list_then_says_checking_products() {
        // Given
        let toolName = "products_list"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Checking products")
    }

    @Test
    func test_label_when_products_update_then_says_updating_products() {
        // Given
        let toolName = "products_update"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Updating products")
    }

    @Test
    func test_label_when_product_variations_list_then_says_checking_product_variations() {
        // Given
        let toolName = "product_variations_list"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Checking product variations")
    }

    @Test
    func test_label_when_product_variations_bulk_update_then_says_updating_product_variations() {
        // Given
        let toolName = "product_variations_bulk_update"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Updating product variations")
    }

    @Test
    func test_label_when_customers_list_then_says_checking_customers() {
        // Given
        let toolName = "customers_list"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Checking customers")
    }

    @Test
    func test_label_when_analytics_revenue_then_says_checking_analytics() {
        // Given
        let toolName = "analytics_revenue"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Checking analytics")
    }

    @Test
    func test_label_when_analytics_orders_then_says_checking_analytics() {
        // Given
        let toolName = "analytics_orders"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Checking analytics")
    }

    @Test
    func test_label_when_unknown_read_tool_then_falls_back_to_generic_read() {
        // Given
        let toolName = "mystery_get"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Checking your store")
    }

    @Test
    func test_label_when_unknown_write_tool_then_falls_back_to_generic_write() {
        // Given
        let toolName = "mystery_update"

        // When
        let label = ToolActivityCopy.label(for: toolName)

        // Then
        #expect(label == "Updating your store")
    }
}
