import Testing
import WooAIAssistant
@testable import WooCommerce

@MainActor
struct AIAssistantExternalViewsAdaptorTests {

    @Test
    func test_orderRow_when_payload_has_id_then_returns_anyview() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = OrderCardPayload(
            id: 963,
            number: "963",
            status: "processing",
            total: "31.20",
            currency: "USD"
        )

        // When
        let row = sut.orderRow(payload: payload, showDivider: true, onTap: {})

        // Then
        #expect(row != nil)
    }

    @Test
    func test_productRow_when_payload_has_name_then_returns_anyview() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = ProductCardPayload(
            id: 101,
            name: "Hoodie",
            price: "49.00",
            stockStatus: "instock"
        )

        // When
        let row = sut.productRow(payload: payload, showDivider: true, onTap: {})

        // Then
        #expect(row != nil)
    }

    @Test
    func test_customerRow_when_payload_has_name_fields_then_returns_anyview() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = CustomerCardPayload(
            id: 7,
            firstName: "Jane",
            lastName: "Doe",
            email: "jane@example.com",
            ordersCount: 3
        )

        // When
        let row = sut.customerRow(payload: payload, showDivider: true, onTap: {})

        // Then
        #expect(row != nil)
    }

    @Test
    func test_customerRow_when_payload_has_no_name_fields_then_returns_nil() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = CustomerCardPayload()

        // When
        let row = sut.customerRow(payload: payload, showDivider: true, onTap: {})

        // Then
        #expect(row == nil)
    }

    @Test
    func test_statsCardView_when_tool_is_analytics_revenue_with_totals_then_returns_anyview() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = AnyCodableJSON.object([
            "totals": .object([
                "gross_sales": .string("1320.00"),
                "net_revenue": .string("1248.05"),
                "currency": .string("USD")
            ]),
            "interval_subtotals": .array([])
        ])

        // When
        let view = sut.statsCardView(toolName: "analytics_revenue", payload: payload)

        // Then
        #expect(view != nil)
    }

    @Test
    func test_statsCardView_when_tool_is_analytics_orders_with_totals_then_returns_anyview() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = AnyCodableJSON.object([
            "totals": .object([
                "orders_count": .int(184),
                "avg_order_value": .string("67.84"),
                "currency": .string("USD")
            ])
        ])

        // When
        let view = sut.statsCardView(toolName: "analytics_orders", payload: payload)

        // Then
        #expect(view != nil)
    }

    @Test
    func test_chartData_when_revenue_intervals_have_total_sales_then_series_matches_each_bucket() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = AnyCodableJSON.object([
            "totals": .object([
                "total_sales": .string("300.00"),
                "net_revenue": .string("250.00"),
                "currency": .string("USD")
            ]),
            "interval_subtotals": .array([
                .object(["interval": .string("2026-05-01"),
                         "subtotals": .object(["total_sales": .double(100.0),
                                               "net_revenue": .double(80.0)])]),
                .object(["interval": .string("2026-05-02"),
                         "subtotals": .object(["total_sales": .double(120.0),
                                               "net_revenue": .double(95.0)])]),
                .object(["interval": .string("2026-05-03"),
                         "subtotals": .object(["total_sales": .double(80.0),
                                               "net_revenue": .double(75.0)])])
            ])
        ])

        // When
        let view = sut.statsCardView(toolName: "analytics_revenue", payload: payload)
        let leading = sut.testChartData(forKeys: ["total_sales", "gross_sales"], payload: payload)
        let trailing = sut.testChartData(forKeys: ["net_revenue"], payload: payload)

        // Then
        #expect(view != nil)
        #expect(leading == [100.0, 120.0, 80.0])
        #expect(trailing == [80.0, 95.0, 75.0])
    }

    @Test
    func test_chartData_when_an_interval_is_missing_a_value_then_other_buckets_still_render() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = AnyCodableJSON.object([
            "totals": .object([
                "orders_count": .int(5),
                "avg_order_value": .string("20.00")
            ]),
            "interval_subtotals": .array([
                .object(["subtotals": .object(["orders_count": .int(2),
                                               "avg_order_value": .double(10.0)])]),
                .object(["subtotals": .object(["orders_count": .int(3)])])
            ])
        ])

        // When
        let leading = sut.testChartData(forKeys: ["orders_count"], payload: payload)
        let trailing = sut.testChartData(forKeys: ["avg_order_value"], payload: payload)

        // Then
        #expect(leading == [2.0, 3.0])
        #expect(trailing == [10.0, 0.0])
    }

    @Test
    func test_chartData_when_intervals_arrive_in_descending_date_order_then_series_is_sorted_ascending() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = AnyCodableJSON.object([
            "totals": .object([
                "total_sales": .string("300.00"),
                "currency": .string("USD")
            ]),
            "interval_subtotals": .array([
                .object(["interval": .string("2026-05-03"),
                         "date_start": .string("2026-05-03 00:00:00"),
                         "subtotals": .object(["total_sales": .double(80.0)])]),
                .object(["interval": .string("2026-05-02"),
                         "date_start": .string("2026-05-02 00:00:00"),
                         "subtotals": .object(["total_sales": .double(120.0)])]),
                .object(["interval": .string("2026-05-01"),
                         "date_start": .string("2026-05-01 00:00:00"),
                         "subtotals": .object(["total_sales": .double(100.0)])])
            ])
        ])

        // When
        let series = sut.testChartData(forKeys: ["total_sales", "gross_sales"], payload: payload)

        // Then
        #expect(series == [100.0, 120.0, 80.0])
    }

    @Test
    func test_statsCardView_when_tool_is_unrelated_then_returns_nil() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = AnyCodableJSON.object(["totals": .object(["orders_count": .int(1)])])

        // When
        let view = sut.statsCardView(toolName: "orders_list", payload: payload)

        // Then
        #expect(view == nil)
    }

    @Test
    func test_statsCardView_when_payload_has_no_totals_or_intervals_then_returns_nil() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = AnyCodableJSON.object(["unrelated": .string("garbage")])

        // When
        let view = sut.statsCardView(toolName: "analytics_revenue", payload: payload)

        // Then
        #expect(view == nil)
    }

    @Test
    func test_formatDateRange_when_dates_are_same_then_renders_one_day() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()

        // When
        let result = sut.formatDateRange(after: "2026-04-30", before: "2026-04-30")

        // Then
        #expect(result == "Apr 30")
    }

    @Test
    func test_formatDateRange_when_range_spans_multiple_days_then_renders_two_dates() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()

        // When
        let result = sut.formatDateRange(after: "2026-04-24", before: "2026-04-30")

        // Then
        #expect(result == "Apr 24 - Apr 30")
    }

    @Test
    func test_formatDateRange_when_either_input_is_nil_then_returns_nil() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()

        // When
        let missingAfter = sut.formatDateRange(after: nil, before: "2026-04-30")
        let missingBefore = sut.formatDateRange(after: "2026-04-24", before: nil)

        // Then
        #expect(missingAfter == nil)
        #expect(missingBefore == nil)
    }

    @Test
    func test_productAccessoryText_when_price_set_then_returns_formatted_price() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = ProductCardPayload(name: "Hoodie", price: "49.00", stockQuantity: 7)

        // When
        let text = sut.productAccessoryText(for: payload)

        // Then
        #expect(text.contains("49"))
    }

    @Test
    func test_productAccessoryText_when_only_regular_price_set_then_returns_formatted_regular_price() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = ProductCardPayload(name: "Hoodie", regularPrice: "49.00")

        // When
        let text = sut.productAccessoryText(for: payload)

        // Then
        #expect(text.contains("49"))
    }

    @Test
    func test_productAccessoryText_when_no_price_then_empty() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = ProductCardPayload(name: "Hoodie")

        // When
        let text = sut.productAccessoryText(for: payload)

        // Then
        #expect(text.isEmpty)
    }

    @Test
    func test_variationAccessoryText_when_price_set_then_returns_formatted_price() {
        // Given
        let sut = AIAssistantExternalViewsAdaptor()
        let payload = ProductVariationCardPayload(id: 1, name: "Red", price: "20.00", stockQuantity: 3)

        // When
        let text = sut.variationAccessoryText(for: payload)

        // Then
        #expect(text.contains("20"))
    }
}
