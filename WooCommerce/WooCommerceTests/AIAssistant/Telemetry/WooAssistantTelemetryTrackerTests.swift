import Testing
import WooAIAssistant
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
struct WooAssistantTelemetryTrackerTests {

    private let context = AssistantTelemetryContext(conversationID: "c",
                                                    requestID: "r",
                                                    messageID: "m")

    @Test
    func test_track_when_conversationStarted_then_forwards_event_to_analytics() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = WooAssistantTelemetryTracker(analytics: analytics)

        // When
        sut.track(.conversationStarted(context: context))

        // Then
        #expect(analyticsProvider.receivedEvents == ["ai_assistant_conversation_started"])
        #expect(analyticsProvider.receivedProperties.last?["conversation_id"] as? String == "c")
        #expect(analyticsProvider.receivedProperties.last?["request_id"] as? String == "r")
        #expect(analyticsProvider.receivedProperties.last?["message_id"] as? String == "m")
    }

    @Test
    func test_track_when_turnStarted_then_includes_version_metadata() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = WooAssistantTelemetryTracker(analytics: analytics)

        // When
        sut.track(.turnStarted(context: context,
                               isRetry: false,
                               completionStack: "jetpack_ai_query",
                               promptVersion: "p1",
                               toolCatalogVersion: "t1"))

        // Then
        #expect(analyticsProvider.receivedEvents == ["ai_assistant_turn_started"])
        #expect(analyticsProvider.receivedProperties.last?["is_retry"] as? Bool == false)
        #expect(analyticsProvider.receivedProperties.last?["completion_stack"] as? String == "jetpack_ai_query")
        #expect(analyticsProvider.receivedProperties.last?["prompt_version"] as? String == "p1")
        #expect(analyticsProvider.receivedProperties.last?["tool_catalog_version"] as? String == "t1")
    }

    @Test
    func test_track_when_toolCallCompleted_success_then_omits_error_kind() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = WooAssistantTelemetryTracker(analytics: analytics)

        // When
        sut.track(.toolCallCompleted(context: context,
                                     toolName: "orders_list",
                                     status: .success,
                                     errorKind: nil,
                                     durationMs: 11))

        // Then
        #expect(analyticsProvider.receivedEvents == ["ai_assistant_tool_call_completed"])
        #expect(analyticsProvider.receivedProperties.last?["status"] as? String == "success")
        #expect(analyticsProvider.receivedProperties.last?["error_kind"] == nil)
        #expect(analyticsProvider.receivedProperties.last?["duration_ms"] as? Int == 11)
    }

    @Test
    func test_track_when_toolCallCompleted_failure_then_includes_error_kind() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = WooAssistantTelemetryTracker(analytics: analytics)

        // When
        sut.track(.toolCallCompleted(context: context,
                                     toolName: "orders_update",
                                     status: .failure,
                                     errorKind: .validationError,
                                     durationMs: nil))

        // Then
        #expect(analyticsProvider.receivedProperties.last?["status"] as? String == "failure")
        #expect(analyticsProvider.receivedProperties.last?["error_kind"] as? String == "validation_error")
    }

    @Test
    func test_track_when_showCardsProcessed_then_emits_aggregate_counts() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = WooAssistantTelemetryTracker(analytics: analytics)

        // When
        sut.track(.showCardsProcessed(context: context,
                                      requestedCount: 4,
                                      renderedCount: 2,
                                      missingCount: 1,
                                      rejectedCount: 1))

        // Then
        #expect(analyticsProvider.receivedEvents == ["ai_assistant_show_cards_processed"])
        #expect(analyticsProvider.receivedProperties.last?["requested_count"] as? Int == 4)
        #expect(analyticsProvider.receivedProperties.last?["rendered_count"] as? Int == 2)
        #expect(analyticsProvider.receivedProperties.last?["missing_count"] as? Int == 1)
        #expect(analyticsProvider.receivedProperties.last?["rejected_count"] as? Int == 1)
    }

    @Test
    func test_track_when_cardTapped_then_emits_bounded_enum_values() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = WooAssistantTelemetryTracker(analytics: analytics)

        // When
        sut.track(.cardTapped(context: context,
                              cardFamily: .order,
                              actionFamily: .openOrder))

        // Then
        #expect(analyticsProvider.receivedEvents == ["ai_assistant_card_tapped"])
        #expect(analyticsProvider.receivedProperties.last?["card_family"] as? String == "order")
        #expect(analyticsProvider.receivedProperties.last?["action_family"] as? String == "open_order")
    }

    @Test
    func test_track_when_turnCompleted_failed_then_includes_error_kind() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = WooAssistantTelemetryTracker(analytics: analytics)

        // When
        sut.track(.turnCompleted(context: context,
                                 outcome: .failed,
                                 durationMs: 999,
                                 errorKind: .network,
                                 isRetry: false,
                                 completionStack: "jetpack_ai_query",
                                 promptVersion: "p1",
                                 toolCatalogVersion: "t1"))

        // Then
        #expect(analyticsProvider.receivedEvents == ["ai_assistant_turn_completed"])
        #expect(analyticsProvider.receivedProperties.last?["outcome"] as? String == "failed")
        #expect(analyticsProvider.receivedProperties.last?["duration_ms"] as? Int == 999)
        #expect(analyticsProvider.receivedProperties.last?["error_kind"] as? String == "network")
    }
}
