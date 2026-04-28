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
              case .array(let familyEnum) = family["enum"],
              case .object(let id) = itemProperties["id"] else {
            Issue.record("expected family enum and id constraints")
            return
        }
        #expect(familyEnum.contains(.string("order")))
        #expect(familyEnum.contains(.string("product")))
        #expect(familyEnum.contains(.string("customer")))
        #expect(id["type"] == .string("string"))
        #expect(id["pattern"] == .string("^[1-9][0-9]*$"))
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
