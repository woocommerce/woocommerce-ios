import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct TypedCardDispatcherTests {

    @Test
    func test_route_when_tool_is_bare_list_name_then_routes_to_unknown() {
        // When
        let routes = ["orders_list", "products_list", "product_variations_list", "customers_list"]
            .map { TypedCardDispatcher.route(for: $0) }

        // Then
        #expect(routes.allSatisfy { $0 == .unknown })
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

        // Then
        #expect(product == .product)
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
