import Foundation
import Testing
@testable import WooAIAssistant

struct ShowCardsToolTests {

    @Test
    func test_definition_advertises_show_cards_with_references_array_schema() {
        // Given
        let tool = ShowCardsTool.make(dataSources: [:])

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
              case .object(let id) = itemProperties["id"],
              case .object(let parentID) = itemProperties["parent_id"] else {
            Issue.record("expected family enum and id constraints")
            return
        }
        #expect(familyEnum.contains(.string("order")))
        #expect(familyEnum.contains(.string("product")))
        #expect(familyEnum.contains(.string("product_variation")))
        #expect(familyEnum.contains(.string("customer")))
        #expect(familyEnum.contains(.string("analytics_stats")))
        #expect(id["type"] == .string("string"))
        #expect(id["pattern"] == nil)
        if case .string(let idDescription) = id["description"] {
            #expect(idDescription.contains("analytics_stats"))
        } else {
            Issue.record("expected id.description string documenting the synthetic format")
        }
        #expect(parentID["type"] == .string("string"))
        #expect(parentID["pattern"] == .string("^[1-9][0-9]*$"))
    }

    @Test
    func test_executor_when_product_reference_uses_numeric_id_then_returns_invalid_tool_call() async {
        // Given
        let tool = ShowCardsTool.make(dataSources: [:])
        let arguments = """
        {"references": [
            {"family": "product", "id": 3723}
        ]}
        """

        // When
        let result = await tool.executor(arguments, NoopWCRESTClient())

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed invalid tool call")
            return
        }
        #expect(failed.kind == .invalidToolCall)
    }

    @Test
    func test_executor_when_analytics_stats_reference_then_renders_card_and_emits_resolved_ref_with_id() async {
        // Given
        let body = """
        {"totals":{"net_revenue":"123.45","gross_sales":"150.00"},
         "intervals":[{"interval":"2026-04-01","date_start":"2026-04-01 00:00:00",
                       "subtotals":{"net_revenue":"50.00"}}]}
        """
        let analyticsID = "analytics_revenue:after:2026-04-01:before:2026-04-30:interval:day:currency:none"
        let tool = ShowCardsTool.make(dataSources: [:])
        let arguments = """
        {"references": [
            {"family": "analytics_stats", "id": "\(analyticsID)"}
        ]}
        """

        // When
        let result = await tool.executor(arguments, StaticWCRESTClient(path: "wc-analytics/reports/revenue/stats", body: body))

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
        let tool = ShowCardsTool.make(dataSources: [:])
        let arguments = """
        {"references": [
            {"family": "analytics_stats", "id": "analytics_revenue:after:not-a-date:before:2026-04-30:interval:day:currency:none"}
        ]}
        """

        // When
        let result = await tool.executor(arguments, NoopWCRESTClient())

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
    func test_executor_when_data_source_resolves_then_summary_carries_only_summary_keys() async {
        // Given
        let payload = OrderCardPayload(id: 3551,
                                       number: "3551",
                                       status: "processing",
                                       total: "120.00",
                                       currency: "USD",
                                       dateCreated: "2024-01-02T03:04:05",
                                       customerName: "Jane Doe",
                                       customerEmail: "jane@example.com")
        let dataSources: [CardFamily: any CardEntityDataSource] = [
            .order: StubDataSource(found: [3551: .order(payload)])
        ]
        let tool = ShowCardsTool.make(dataSources: dataSources)
        let arguments = #"{"references": [{"family": "order", "id": "3551"}]}"#

        // When
        let result = await tool.executor(arguments, NoopWCRESTClient())

        // Then
        guard case .success(let success) = result,
              case .object(let structured) = success.structured,
              case .array(let resolvedRefs) = structured["resolved_refs"],
              resolvedRefs.count == 1,
              case .object(let firstRef) = resolvedRefs[0],
              case .object(let summary) = firstRef["summary"] else {
            Issue.record("expected resolved summary object")
            return
        }
        #expect(summary["id"] == .int(3551))
        #expect(summary["number"] == .string("3551"))
        #expect(summary["customer_name"] == .string("Jane Doe"))
        #expect(summary["customer_email"] == nil)
    }

    @Test
    func test_executor_when_data_source_resolves_then_uiStructured_card_element_carries_full_entity() async {
        // Given
        let payload = OrderCardPayload(id: 3551,
                                       number: "3551",
                                       status: "processing",
                                       total: "120.00",
                                       customerEmail: "jane@example.com")
        let dataSources: [CardFamily: any CardEntityDataSource] = [
            .order: StubDataSource(found: [3551: .order(payload)])
        ]
        let tool = ShowCardsTool.make(dataSources: dataSources)
        let arguments = #"{"references": [{"family": "order", "id": "3551"}]}"#

        // When
        let result = await tool.executor(arguments, NoopWCRESTClient())

        // Then
        guard case .success(let success) = result, let cards = success.uiStructured?.cards else {
            Issue.record("expected uiStructured cards")
            return
        }
        #expect(cards.count == 1)
        #expect(cards[0].family == .order)
        #expect(cards[0].id == "3551")
        guard case .object(let dict) = cards[0].element else {
            Issue.record("expected element object")
            return
        }
        #expect(dict["customer_email"] == .string("jane@example.com"))
    }
}

private struct StubDataSource: CardEntityDataSource {
    private let found: [Int64: CardEntity]

    init(found: [Int64: CardEntity]) {
        self.found = found
    }

    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        var outcomes: [CardRef: CardEntityOutcome] = [:]
        for ref in refs {
            if let entity = found[ref.id] {
                outcomes[ref] = .found(entity)
            } else {
                outcomes[ref] = .rejected(.notFound)
            }
        }
        return outcomes
    }
}

private struct StaticWCRESTClient: WCRESTClient {
    let path: String
    let body: String

    func request(method: String,
                 path requestedPath: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse {
        guard requestedPath == path else {
            return WCRESTResponse(data: Data(), statusCode: 404)
        }
        return WCRESTResponse(data: Data(self.body.utf8), statusCode: 200)
    }
}
