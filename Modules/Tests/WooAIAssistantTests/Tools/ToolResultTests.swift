import Foundation
import Testing
@testable import WooAIAssistant

struct ToolResultTests {
    @Test
    func test_toolResult_when_success_then_carries_structured_and_optional_uiStructured() {
        // Given
        let structured = AnyCodableJSON.object([
            "count": .int(2),
            "ids": .array([.int(3551), .int(3548)])
        ])
        let uiStructured = UIStructured(cards: [
            RenderedCardPayload(family: .order, id: 3551, element: .object(["id": .int(3551)]))
        ])

        // When
        let result: ToolResult = .success(.init(
            toolName: "show_cards",
            toolCallID: "call_1",
            structured: structured,
            uiStructured: uiStructured
        ))

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected .success, got \(result)")
            return
        }
        #expect(success.toolName == "show_cards")
        #expect(success.toolCallID == "call_1")
        #expect(success.structured == structured)
        #expect(success.uiStructured?.cards.count == 1)
        #expect(success.uiStructured?.cards.first?.family == .order)
        #expect(success.uiStructured?.cards.first?.id == 3551)
    }

    @Test
    func test_toolResult_when_success_without_uiStructured_then_uiStructured_is_nil() {
        // Given / When
        let result: ToolResult = .success(.init(
            toolName: "orders_list",
            toolCallID: "call_2",
            structured: .object(["count": .int(0)])
        ))

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected .success, got \(result)")
            return
        }
        #expect(success.uiStructured == nil)
    }

    @Test
    func test_toolResult_when_failed_then_carries_kind_reason_code() {
        // Given / When
        let result: ToolResult = .failed(.init(
            toolName: "orders_get",
            toolCallID: "call_3",
            kind: .upstreamFailure,
            reason: "HTTP 502 from upstream",
            code: "bad_gateway"
        ))

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected .failed, got \(result)")
            return
        }
        #expect(failed.toolName == "orders_get")
        #expect(failed.toolCallID == "call_3")
        #expect(failed.kind == .upstreamFailure)
        #expect(failed.reason == "HTTP 502 from upstream")
        #expect(failed.code == "bad_gateway")
    }

    @Test
    func test_toolResult_when_failed_without_code_then_code_is_nil() {
        // Given / When
        let result: ToolResult = .failed(.init(
            toolName: "orders_get",
            toolCallID: "call_4",
            kind: .network,
            reason: "offline"
        ))

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected .failed, got \(result)")
            return
        }
        #expect(failed.code == nil)
    }

    @Test
    func test_toolResult_when_rejectedBySafety_then_carries_reason() {
        // Given / When
        let result: ToolResult = .rejectedBySafety(.init(
            toolName: "orders_update",
            toolCallID: "call_5",
            reason: "destructive write requires confirmation"
        ))

        // Then
        guard case .rejectedBySafety(let rejection) = result else {
            Issue.record("expected .rejectedBySafety, got \(result)")
            return
        }
        #expect(rejection.toolName == "orders_update")
        #expect(rejection.reason == "destructive write requires confirmation")
    }

    @Test
    func test_toolResult_when_awaitingConfirmation_then_carries_proposal() {
        // Given
        let proposal = AnyCodableJSON.object([
            "tool": .string("orders_update"),
            "id": .int(3551),
            "changes": .object(["status": .string("completed")])
        ])

        // When
        let result: ToolResult = .awaitingConfirmation(.init(
            toolName: "orders_update",
            toolCallID: "call_6",
            proposal: proposal
        ))

        // Then
        guard case .awaitingConfirmation(let confirmation) = result else {
            Issue.record("expected .awaitingConfirmation, got \(result)")
            return
        }
        #expect(confirmation.toolName == "orders_update")
        #expect(confirmation.proposal == proposal)
    }

    @Test
    func test_anyCodableJSON_when_encoded_to_json_then_round_trips_back() throws {
        // Given
        let original: AnyCodableJSON = .object([
            "id": .int(3551),
            "total": .double(99.99),
            "currency": .string("USD"),
            "paid": .bool(true),
            "tags": .array([.string("urgent"), .string("vip")]),
            "billing_address": .null
        ])

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodableJSON.self, from: data)

        // Then
        #expect(decoded == original)
    }

    @Test
    func test_renderedCardPayload_when_round_tripped_through_uiStructured_then_preserves_all_fields() {
        // Given
        let element = AnyCodableJSON.object([
            "id": .int(3551),
            "status": .string("processing")
        ])
        let payload = RenderedCardPayload(family: .order, id: 3551, element: element)

        // When
        let envelope = UIStructured(cards: [payload])

        // Then
        let card = envelope.cards.first
        #expect(card?.family == .order)
        #expect(card?.id == 3551)
        #expect(card?.element == element)
    }

    @Test
    func test_cardFamilyID_when_decoded_from_json_then_matches_enum_case() throws {
        // Given
        let json = Data(#"["order","product","customer"]"#.utf8)

        // When
        let decoded = try JSONDecoder().decode([CardFamilyID].self, from: json)

        // Then
        #expect(decoded == [.order, .product, .customer])
    }
}
