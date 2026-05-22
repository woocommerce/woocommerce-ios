import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AnalyticsProductsToolTests {
    @Test
    func test_analytics_products_definition_documents_time_window_versus_all_time_popularity() {
        // Given
        let tool = AnalyticsProductsTool.make()

        // Then
        #expect(tool.definition.description.contains("Top-selling products within a date range"))
        #expect(tool.definition.description.contains("products_list with orderby=popularity"))
        #expect(tool.definition.description.contains("show_cards"))
    }

    @Test
    func test_analytics_products_when_response_ok_then_query_uses_iso_bounds_orderby_and_extended_info() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = AnalyticsProductsTool.make()

        // When
        _ = await tool.executor(
            #"{"after":"2026-04-01","before":"2026-04-30","orderby":"net_revenue","per_page":5}"#,
            client
        )

        // Then
        let call = await client.calls.first
        #expect(call?.path == "wc-analytics/reports/products")
        #expect(call?.query["after"] == "2026-04-01T00:00:00")
        #expect(call?.query["before"] == "2026-04-30T23:59:59")
        #expect(call?.query["orderby"] == "net_revenue")
        #expect(call?.query["order"] == "desc")
        #expect(call?.query["per_page"] == "5")
        #expect(call?.query["extended_info"] == "true")
    }

    @Test
    func test_analytics_products_when_orderby_omitted_then_defaults_to_items_sold() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = AnalyticsProductsTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        #expect(await client.calls.first?.query["orderby"] == "items_sold")
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["orderby"] == .string("items_sold"))
    }

    @Test
    func test_analytics_products_when_rows_present_then_each_row_projects_metrics_and_extended_info() async {
        // Given
        let body = """
        [
            {
                "product_id": 815, "items_sold": 4462, "net_revenue": 80455.38, "orders_count": 795,
                "extended_info": {
                    "name": "Ribbed Wool Beanie", "sku": "RWB-1", "price": 17.09, "stock_status": "instock",
                    "image": "<img src=\\"x\\" />", "permalink": "https://example.com/p", "category_ids": [1, 2]
                }
            }
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = AnalyticsProductsTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let products) = fields["products"],
              case .object(let first) = products.first else {
            Issue.record("expected first product object")
            return
        }
        #expect(first["product_id"] == .int(815))
        #expect(first["items_sold"] == .int(4462))
        #expect(first["net_revenue"] == .string("80455.38"))
        #expect(first["orders_count"] == .int(795))
        #expect(first["name"] == .string("Ribbed Wool Beanie"))
        #expect(first["sku"] == .string("RWB-1"))
        #expect(first["price"] == .string("17.09"))
        #expect(first["stock_status"] == .string("instock"))
        #expect(first["target"] == .object(["kind": .string("product"), "id": .int(815)]))
        // Heavy extended_info fields must be projected away to protect the payload budget.
        #expect(first["image"] == nil)
        #expect(first["permalink"] == nil)
        #expect(first["category_ids"] == nil)
    }

    @Test
    func test_analytics_products_when_required_dates_missing_then_returns_failed_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = AnalyticsProductsTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_analytics_products_when_date_invalid_then_returns_failed_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = AnalyticsProductsTool.make()

        // When
        let result = await tool.executor(#"{"after":"last week","before":"2026-04-30"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_analytics_products_when_orderby_not_in_enum_then_returns_failed_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = AnalyticsProductsTool.make()

        // When
        let result = await tool.executor(
            #"{"after":"2026-04-01","before":"2026-04-30","orderby":"date"}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
    }

    @Test
    func test_analytics_products_when_response_is_500_then_returns_failed_with_upstream_failure() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 500))
        let tool = AnalyticsProductsTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .upstreamFailure)
    }

    @Test
    func test_analytics_products_when_per_page_above_50_then_query_clamps_to_50() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = AnalyticsProductsTool.make()

        // When
        _ = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30","per_page":500}"#, client)

        // Then
        #expect(await client.calls.first?.query["per_page"] == "50")
    }

    @Test
    func test_analytics_products_when_per_page_below_1_then_query_clamps_to_1() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = AnalyticsProductsTool.make()

        // When
        _ = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30","per_page":0}"#, client)

        // Then
        #expect(await client.calls.first?.query["per_page"] == "1")
    }

    @Test
    func test_analytics_products_when_per_page_omitted_then_query_uses_default_of_20() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = AnalyticsProductsTool.make()

        // When
        _ = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        #expect(await client.calls.first?.query["per_page"] == "20")
    }

    @Test
    func test_analytics_products_when_empty_report_then_count_zero_and_products_empty() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = AnalyticsProductsTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["count"] == .int(0))
        #expect(fields["products"] == .array([]))
        #expect(fields["truncated"] == nil)
    }

    @Test
    func test_analytics_products_when_row_missing_product_id_then_row_dropped() async {
        // Given
        let body = """
        [
            {"items_sold": 10, "net_revenue": 99.0, "extended_info": {"name": "No ID"}},
            {"product_id": 7, "items_sold": 5, "net_revenue": 50.0, "extended_info": {"name": "Has ID"}}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = AnalyticsProductsTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let products) = fields["products"],
              case .object(let only) = products.first else {
            Issue.record("expected one surviving product object")
            return
        }
        #expect(products.count == 1)
        #expect(only["product_id"] == .int(7))
        #expect(only["name"] == .string("Has ID"))
        #expect(only["target"] == .object(["kind": .string("product"), "id": .int(7)]))
    }

    @Test
    func test_analytics_products_when_unknown_argument_then_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = AnalyticsProductsTool.make()

        // When
        let result = await tool.executor(
            #"{"after":"2026-04-01","before":"2026-04-30","interval":"day"}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }
}
