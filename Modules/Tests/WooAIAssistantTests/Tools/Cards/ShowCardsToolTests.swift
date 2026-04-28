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
              case .array(let familyEnum) = family["enum"] else {
            Issue.record("expected family enum constraint")
            return
        }
        #expect(familyEnum.contains(.string("order")))
        #expect(familyEnum.contains(.string("product")))
        #expect(familyEnum.contains(.string("customer")))
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
    func test_executor_when_two_resolved_one_rejected_then_structured_summary_lists_all_three_and_uiStructured_only_resolved() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/orders/3551",
                    response: StubResponses.ok("""
                    {"id": 3551, "status": "processing", "total": "120.00", "currency": "USD",
                     "billing": {"first_name": "Jane", "last_name": "Doe"}}
                    """))
        client.stub(path: "wc/v3/orders/3548",
                    response: StubResponses.ok("""
                    {"id": 3548, "status": "on-hold", "total": "75.00", "currency": "USD"}
                    """))
        client.stub(path: "wc/v3/orders/9999", response: StubResponses.failure(statusCode: 404))
        let tool = ShowCardsTool.make()
        let arguments = """
        {"references": [
            {"family": "order", "id": 3551},
            {"family": "order", "id": 3548},
            {"family": "order", "id": 9999}
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
        #expect(structured["resolved"] == .int(2))
        #expect(structured["rejected"] == .int(1))
        guard case .array(let entries) = structured["resolutions"] else {
            Issue.record("expected resolutions array")
            return
        }
        #expect(entries.count == 3)
        guard case .object(let firstResolved) = entries[0] else {
            Issue.record("expected first resolution to be object")
            return
        }
        #expect(firstResolved["status"] == .string("resolved"))
        #expect(firstResolved["family"] == .string("order"))
        #expect(firstResolved["id"] == .int(3551))
        guard case .object(let summary) = firstResolved["summary"] else {
            Issue.record("expected summary object")
            return
        }
        #expect(summary["status"] == .string("processing"))
        #expect(summary["customer_name"] == .string("Jane Doe"))

        guard case .object(let rejected) = entries[2] else {
            Issue.record("expected rejected object")
            return
        }
        #expect(rejected["status"] == .string("rejected"))
        #expect(rejected["reason"] == .string("notFound"))
        #expect(rejected["id"] == .int(9999))

        let cards = success.uiStructured?.cards ?? []
        #expect(cards.count == 2)
        #expect(cards[0].family == .order)
        #expect(cards[0].id == 3551)
        #expect(cards[1].family == .order)
        #expect(cards[1].id == 3548)
    }

    @Test
    func test_executor_when_only_rejected_references_then_uiStructured_is_nil() async {
        // Given
        let client = StubbedWCRESTClient()
        client.setFallback(StubResponses.failure(statusCode: 404))
        let tool = ShowCardsTool.make()
        let arguments = """
        {"references": [{"family": "order", "id": 9999}]}
        """

        // When
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        #expect(success.uiStructured == nil)
        if case .object(let structured) = success.structured {
            #expect(structured["resolved"] == .int(0))
            #expect(structured["rejected"] == .int(1))
        } else {
            Issue.record("expected object structured")
        }
    }
}
