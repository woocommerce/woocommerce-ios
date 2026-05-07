import Foundation
import Testing
@testable import WooAIAssistant

struct ShowCardsToolTests {
    @Test
    func test_definition_advertises_show_cards_with_references_array_schema() {
        // Given
        let tool = ShowCardsTool.make()

        // When
        let definition = tool.definition

        // Then
        #expect(definition.name == "show_cards")
        #expect(definition.description.contains("After a successful `analytics_revenue` or `analytics_orders`"))
        #expect(definition.description.contains("call this tool with family `analytics_stats`"))
        #expect(definition.description.contains("A single call may mix families"))
        #expect(definition.description.contains("For broad product inventory lists, render product"))
        let schema = definition.parametersSchema
        guard case .object(let root) = schema,
              case .object(let properties) = root["properties"],
              case .object(let references) = properties["references"] else {
            Issue.record("expected nested schema shape")
            return
        }
        #expect(references["type"] == .string("array"))
        #expect(references["minItems"] == .int(1))
        #expect(references["maxItems"] == .int(10))
        guard case .object(let items) = references["items"],
              case .object(let itemProperties) = items["properties"],
              case .object(let family) = itemProperties["family"],
              case .array(let familyEnum) = family["enum"],
              case .object(let id) = itemProperties["id"] else {
            Issue.record("expected family enum and id constraints")
            return
        }
        #expect(familyEnum.contains(.string("order")))
        #expect(familyEnum.contains(.string("product")))
        #expect(familyEnum.contains(.string("product_variation")))
        #expect(familyEnum.contains(.string("customer")))
        #expect(familyEnum.contains(.string("analytics_stats")))
        #expect(id["type"] == .string("string"))
        // No pattern on `id` - resolver-side AnalyticsCardSpec.decode validates synthetic format.
        #expect(id["pattern"] == nil)
        if case .string(let idDescription) = id["description"] {
            #expect(idDescription.contains("analytics_stats"))
        } else {
            Issue.record("expected id.description string documenting the synthetic format")
        }
        guard case .object(let parentID) = itemProperties["parent_id"] else {
            Issue.record("expected parent_id property in item schema")
            return
        }
        #expect(parentID["type"] == .string("string"))
        #expect(parentID["pattern"] == .string("^[1-9][0-9]*$"))
    }

    @Test
    func test_executor_when_product_reference_uses_numeric_id_then_returns_invalid_tool_call() async {
        // Given
        let client = StubbedWCRESTClient()
        let tool = ShowCardsTool.make()
        let arguments = """
        {"references": [
            {"family": "product", "id": 3723}
        ]}
        """

        // When
        let result = await tool.executor(arguments, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed invalid tool call")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_executor_when_analytics_stats_reference_then_renders_card_and_emits_resolved_ref_with_id() async {
        // Given
        let body = """
        {"totals":{"net_revenue":"123.45","gross_sales":"150.00"},
         "intervals":[{"interval":"2026-04-01","date_start":"2026-04-01 00:00:00",
                       "subtotals":{"net_revenue":"50.00"}}]}
        """
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc-analytics/reports/revenue/stats", response: StubResponses.ok(body))
        let analyticsID = "analytics_revenue:after:2026-04-01:before:2026-04-30:interval:day:currency:none"
        let tool = ShowCardsTool.make()
        let arguments = """
        {"references": [
            {"family": "analytics_stats", "id": "\(analyticsID)"}
        ]}
        """

        // When
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success(let success) = result,
              case .object(let structured) = success.structured,
              case .array(let resolvedRefs) = structured["resolved_refs"],
              case .object(let entry) = resolvedRefs.first else {
            Issue.record("expected resolved_refs with one entry")
            return
        }
        #expect(entry["family"] == .string("analytics_stats"))
        #expect(entry["id"] == .string(analyticsID))
        let cards = success.uiStructured?.cards ?? []
        #expect(cards.count == 1)
        #expect(cards[0].family == .analyticsStats)
        #expect(cards[0].id == analyticsID)
    }

    @Test
    func test_executor_when_analytics_id_is_malformed_then_rejected_as_malformed() async {
        // Given
        let client = StubbedWCRESTClient()
        let tool = ShowCardsTool.make()
        let arguments = """
        {"references": [
            {"family": "analytics_stats", "id": "analytics_revenue:after:not-a-date:before:2026-04-30:interval:day:currency:none"}
        ]}
        """

        // When
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success(let success) = result,
              case .object(let structured) = success.structured,
              case .array(let rejectedRefs) = structured["rejected_refs"],
              case .object(let entry) = rejectedRefs.first else {
            Issue.record("expected rejected_refs with one entry")
            return
        }
        #expect(entry["family"] == .string("analytics_stats"))
        #expect(entry["reason"] == .string("malformed"))
        #expect(success.uiStructured == nil)
    }

    @Test
    func test_executor_when_product_variation_with_parent_id_then_resolves_via_nested_path() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/products/821/variations/822",
                    response: StubResponses.ok("""
                    {"id": 822, "name": "Black", "sku": "BNY-BLK", "price": "74.99",
                     "stock_status": "instock", "parent_id": 821}
                    """))
        let tool = ShowCardsTool.make()
        let arguments = """
        {"references": [
            {"family": "product_variation", "id": "822", "parent_id": "821"}
        ]}
        """

        // When
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let cards = success.uiStructured?.cards ?? []
        #expect(cards.count == 1)
        #expect(cards[0].family == .productVariation)
        #expect(cards[0].id == "822")
    }

    @Test
    func test_executor_when_product_variation_missing_parent_id_then_rejected_as_malformed() async {
        // Given
        let client = StubbedWCRESTClient()
        let tool = ShowCardsTool.make()
        let arguments = """
        {"references": [
            {"family": "product_variation", "id": "822"}
        ]}
        """

        // When
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        guard case .object(let structured) = success.structured,
              case .array(let rejectedRefs) = structured["rejected_refs"] else {
            Issue.record("expected rejected_refs array")
            return
        }
        #expect(rejectedRefs.count == 1)
        if case .object(let entry) = rejectedRefs[0] {
            #expect(entry["reason"] == .string("malformed"))
            #expect(entry["family"] == .string("product_variation"))
        } else {
            Issue.record("expected rejected entry object")
        }
        #expect(success.uiStructured == nil)
    }

    @Test
    func test_executor_when_arguments_not_decodable_then_returns_failed_invalid_tool_call() async {
        // Given
        let client = StubbedWCRESTClient()
        let tool = ShowCardsTool.make()

        // When
        let result = await tool.executor("not json", client)

        // Then
        if case .failed(let failed) = result {
            #expect(failed.kind == .invalidToolCall)
        } else {
            Issue.record("expected failed.invalidToolCall")
        }
    }

    @Test
    func test_executor_when_one_resolved_one_missing_one_duplicate_then_projection_splits_three_buckets() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("""
                    [{"id": 3551, "status": "processing", "total": "120.00", "currency": "USD",
                      "billing": {"first_name": "Jane", "last_name": "Doe"}}]
                    """))
        let tool = ShowCardsTool.make()
        let arguments = """
        {"references": [
            {"family": "order", "id": "3551"},
            {"family": "order", "id": "9999"},
            {"family": "order", "id": "3551"}
        ]}
        """

        // When
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        guard case .object(let structured) = success.structured else {
            Issue.record("expected object structured")
            return
        }
        #expect(structured["requested"] == .int(3))
        #expect(structured["validated"] == .int(2))
        #expect(structured["rendered"] == .int(1))
        guard case .array(let resolvedRefs) = structured["resolved_refs"],
              case .array(let missingRefs) = structured["missing_refs"],
              case .array(let rejectedRefs) = structured["rejected_refs"] else {
            Issue.record("expected resolved_refs/missing_refs/rejected_refs arrays")
            return
        }
        #expect(resolvedRefs.count == 1)
        #expect(missingRefs.count == 1)
        #expect(rejectedRefs.count == 1)

        guard case .object(let firstResolved) = resolvedRefs[0],
              case .object(let summary) = firstResolved["summary"] else {
            Issue.record("expected resolved with summary object")
            return
        }
        #expect(firstResolved["family"] == .string("order"))
        #expect(firstResolved["id"] == .string("3551"))
        #expect(summary["status"] == .string("processing"))
        #expect(summary["customer_name"] == .string("Jane Doe"))

        guard case .object(let missing) = missingRefs[0] else {
            Issue.record("expected missing object")
            return
        }
        #expect(missing["reason"] == .string("notFound"))
        #expect(missing["id"] == .string("9999"))

        guard case .object(let rejected) = rejectedRefs[0] else {
            Issue.record("expected rejected object")
            return
        }
        #expect(rejected["reason"] == .string("duplicate"))

        let cards = success.uiStructured?.cards ?? []
        #expect(cards.count == 1)
        #expect(cards[0].family == .order)
        #expect(cards[0].id == "3551")
    }
}
