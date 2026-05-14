import Testing
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
struct AssistantTrackableEventsTests {

    @Test
    func test_conversationStarted_emits_expected_name_and_properties() {
        // When
        let event = AiAssistantConversationStartedEvent(
            conversationId: "c",
            requestId: "r",
            messageId: "m"
        )

        // Then
        #expect(event.analyticsName == "ai_assistant_conversation_started")
        let properties = event.analyticsProperties
        #expect(properties["conversation_id"] as? String == "c")
        #expect(properties["request_id"] as? String == "r")
        #expect(properties["message_id"] as? String == "m")
        let expectedKeys: Set<String> = ["conversation_id", "request_id", "message_id"]
        #expect(Set(properties.keys) == expectedKeys)
    }

    @Test
    func test_turnStarted_emits_expected_name_and_properties() {
        // When
        let event = AiAssistantTurnStartedEvent(
            conversationId: "c",
            requestId: "r",
            messageId: "m",
            isRetry: true,
            completionStack: "jetpack_ai_query",
            promptVersion: "p1",
            toolCatalogVersion: "t1"
        )

        // Then
        #expect(event.analyticsName == "ai_assistant_turn_started")
        let properties = event.analyticsProperties
        #expect(properties["conversation_id"] as? String == "c")
        #expect(properties["request_id"] as? String == "r")
        #expect(properties["message_id"] as? String == "m")
        #expect(properties["is_retry"] as? Bool == true)
        #expect(properties["completion_stack"] as? String == "jetpack_ai_query")
        #expect(properties["prompt_version"] as? String == "p1")
        #expect(properties["tool_catalog_version"] as? String == "t1")
        let expectedKeys: Set<String> = [
            "conversation_id", "request_id", "message_id",
            "is_retry", "completion_stack", "prompt_version", "tool_catalog_version"
        ]
        #expect(Set(properties.keys) == expectedKeys)
    }

    @Test
    func test_toolCallCompleted_when_success_then_omits_error_kind_and_includes_duration() {
        // When
        let event = AiAssistantToolCallCompletedEvent(
            conversationId: "c",
            requestId: "r",
            messageId: "m",
            toolName: "orders_list",
            status: .success,
            errorKind: nil,
            durationMs: 42
        )

        // Then
        #expect(event.analyticsName == "ai_assistant_tool_call_completed")
        let properties = event.analyticsProperties
        #expect(properties["tool_name"] as? String == "orders_list")
        #expect(properties["status"] as? String == "success")
        #expect(properties["error_kind"] == nil)
        #expect(properties["duration_ms"] as? Int == 42)
        let expectedKeys: Set<String> = [
            "conversation_id", "request_id", "message_id",
            "tool_name", "status", "duration_ms"
        ]
        #expect(Set(properties.keys) == expectedKeys)
    }

    @Test
    func test_toolCallCompleted_when_failure_then_includes_error_kind_and_omits_duration() {
        // When
        let event = AiAssistantToolCallCompletedEvent(
            conversationId: "c",
            requestId: "r",
            messageId: "m",
            toolName: "orders_update",
            status: .failure,
            errorKind: .validationError,
            durationMs: nil
        )

        // Then
        let properties = event.analyticsProperties
        #expect(properties["status"] as? String == "failure")
        #expect(properties["error_kind"] as? String == "validation_error")
        #expect(properties["duration_ms"] == nil)
        let expectedKeys: Set<String> = [
            "conversation_id", "request_id", "message_id",
            "tool_name", "status", "error_kind"
        ]
        #expect(Set(properties.keys) == expectedKeys)
    }

    @Test
    func test_showCardsProcessed_emits_expected_counts() {
        // When
        let event = AiAssistantShowCardsProcessedEvent(
            conversationId: "c",
            requestId: "r",
            messageId: "m",
            requestedCount: 4,
            renderedCount: 2,
            missingCount: 1,
            rejectedCount: 1
        )

        // Then
        #expect(event.analyticsName == "ai_assistant_show_cards_processed")
        let properties = event.analyticsProperties
        #expect(properties["requested_count"] as? Int == 4)
        #expect(properties["rendered_count"] as? Int == 2)
        #expect(properties["missing_count"] as? Int == 1)
        #expect(properties["rejected_count"] as? Int == 1)
        let expectedKeys: Set<String> = [
            "conversation_id", "request_id", "message_id",
            "requested_count", "rendered_count", "missing_count", "rejected_count"
        ]
        #expect(Set(properties.keys) == expectedKeys)
    }

    @Test
    func test_cardTapped_emits_bounded_enum_values() {
        // When
        let event = AiAssistantCardTappedEvent(
            conversationId: "c",
            requestId: "r",
            messageId: "m",
            cardFamily: .order,
            actionFamily: .openOrder
        )

        // Then
        #expect(event.analyticsName == "ai_assistant_card_tapped")
        let properties = event.analyticsProperties
        #expect(properties["card_family"] as? String == "order")
        #expect(properties["action_family"] as? String == "open_order")
        let expectedKeys: Set<String> = [
            "conversation_id", "request_id", "message_id",
            "card_family", "action_family"
        ]
        #expect(Set(properties.keys) == expectedKeys)
    }

    @Test
    func test_turnCompleted_when_failed_then_includes_error_kind() {
        // When
        let event = AiAssistantTurnCompletedEvent(
            conversationId: "c",
            requestId: "r",
            messageId: "m",
            outcome: .failed,
            durationMs: 1234,
            errorKind: .network,
            isRetry: false,
            completionStack: "jetpack_ai_query",
            promptVersion: "p1",
            toolCatalogVersion: "t1"
        )

        // Then
        #expect(event.analyticsName == "ai_assistant_turn_completed")
        let properties = event.analyticsProperties
        #expect(properties["outcome"] as? String == "failed")
        #expect(properties["duration_ms"] as? Int == 1234)
        #expect(properties["error_kind"] as? String == "network")
        #expect(properties["is_retry"] as? Bool == false)
        let expectedKeys: Set<String> = [
            "conversation_id", "request_id", "message_id",
            "outcome", "duration_ms", "error_kind", "is_retry",
            "completion_stack", "prompt_version", "tool_catalog_version"
        ]
        #expect(Set(properties.keys) == expectedKeys)
    }

    @Test
    func test_turnCompleted_when_success_then_omits_error_kind() {
        // When
        let event = AiAssistantTurnCompletedEvent(
            conversationId: "c",
            requestId: "r",
            messageId: "m",
            outcome: .success,
            durationMs: 99,
            errorKind: nil,
            isRetry: false,
            completionStack: "jetpack_ai_query",
            promptVersion: "p1",
            toolCatalogVersion: "t1"
        )

        // Then
        let properties = event.analyticsProperties
        #expect(properties["outcome"] as? String == "success")
        #expect(properties["error_kind"] == nil)
        let expectedKeys: Set<String> = [
            "conversation_id", "request_id", "message_id",
            "outcome", "duration_ms", "is_retry",
            "completion_stack", "prompt_version", "tool_catalog_version"
        ]
        #expect(Set(properties.keys) == expectedKeys)
    }
}
