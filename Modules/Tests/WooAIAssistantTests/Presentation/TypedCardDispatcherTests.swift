import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct TypedCardDispatcherTests {

    @Test
    func test_route_when_tool_is_orders_list_then_routes_to_orders_list() {
        // When
        let route = TypedCardDispatcher.route(for: "orders_list")

        // Then
        #expect(route == .ordersList)
    }

    @Test
    func test_route_when_tool_is_products_list_then_routes_to_products_list() {
        // When
        let route = TypedCardDispatcher.route(for: "products_list")

        // Then
        #expect(route == .productsList)
    }

    @Test
    func test_route_when_tool_is_product_variations_list_then_routes_to_product_variations_list() {
        // When
        let route = TypedCardDispatcher.route(for: "product_variations_list")

        // Then
        #expect(route == .productVariationsList)
    }

    @Test
    func test_route_when_tool_is_customers_list_then_routes_to_customers_list() {
        // When
        let route = TypedCardDispatcher.route(for: "customers_list")

        // Then
        #expect(route == .customersList)
    }

    @Test
    func test_route_when_tool_is_analytics_revenue_or_orders_then_routes_to_analytics_stats() {
        // When
        let revenue = TypedCardDispatcher.route(for: "analytics_revenue")
        let orders = TypedCardDispatcher.route(for: "analytics_orders")

        // Then
        #expect(revenue == .analyticsStats)
        #expect(orders == .analyticsStats)
    }

    @Test
    func test_route_when_tool_is_show_cards_order_then_routes_to_order() {
        // When
        let route = TypedCardDispatcher.route(for: "show_cards.order")

        // Then
        #expect(route == .order)
    }

    @Test
    func test_route_when_tool_is_orders_get_dot_order_then_routes_to_order() {
        // When
        let route = TypedCardDispatcher.route(for: "orders_get.order")

        // Then
        #expect(route == .order)
    }

    @Test
    func test_route_when_tool_is_show_cards_product_then_routes_to_product() {
        // When
        let product = TypedCardDispatcher.route(for: "show_cards.product")
        let bulk = TypedCardDispatcher.route(for: "products_bulk_update.product")

        // Then
        #expect(product == .product)
        #expect(bulk == .product)
    }

    @Test
    func test_route_when_tool_is_show_cards_product_variation_then_routes_to_product_variation() {
        // When
        let route = TypedCardDispatcher.route(for: "show_cards.product_variation")

        // Then
        #expect(route == .productVariation)
    }

    @Test
    func test_route_when_tool_is_show_cards_customer_then_routes_to_customer() {
        // When
        let route = TypedCardDispatcher.route(for: "show_cards.customer")

        // Then
        #expect(route == .customer)
    }

    @Test
    func test_route_when_tool_has_unknown_family_then_routes_to_unknown() {
        // When
        let unknownDot = TypedCardDispatcher.route(for: "show_cards.banana")
        let unknownPlain = TypedCardDispatcher.route(for: "settings_get")

        // Then
        #expect(unknownDot == .unknown)
        #expect(unknownPlain == .unknown)
    }
}
