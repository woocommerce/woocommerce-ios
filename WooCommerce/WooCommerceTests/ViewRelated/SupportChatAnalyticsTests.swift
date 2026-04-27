import Foundation
import Testing
import Yosemite
@testable import WooCommerce

/// Verifies the analytics event factory output for support chat events.
///
struct SupportChatAnalyticsTests {

    private func track(_ event: WooAnalyticsEvent, on provider: MockAnalyticsProvider) {
        WooAnalytics(analyticsProvider: provider).track(event: event)
    }

    // MARK: - opened

    @Test func opened_fires_event_with_entry_point_auth_state_and_resumed_flag() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.opened(entryPoint: .helpSettings,
                                  authState: .wpcom,
                                  chatResumed: true),
              on: provider)

        // Then
        #expect(provider.receivedEvents == ["support_chat_opened"])
        let properties = try! #require(provider.properties(for: "support_chat_opened"))
        #expect(properties["entry_point"] as? String == "help_settings")
        #expect(properties["auth_state"] as? String == "wpcom")
        #expect(properties["chat_resumed"] as? Bool == true)
    }

    // MARK: - messageSent

    @Test func messageSent_when_first_turn_then_omits_chat_id() {
        // Given — first turn means `chatID` is nil; the absence of the property carries the signal.
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.messageSent(chatID: nil, entryPoint: .connectivityTool),
              on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_message_sent"))
        #expect(properties["chat_id"] == nil)
        #expect(properties["entry_point"] as? String == "connectivity_tool")
    }

    @Test func messageSent_when_chat_id_provided_then_includes_it() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.messageSent(chatID: 4242, entryPoint: .helpSettings),
              on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_message_sent"))
        #expect(properties["chat_id"] as? Int64 == 4242)
        #expect(properties["entry_point"] as? String == "help_settings")
    }

    // MARK: - messageReceived

    @Test func messageReceived_carries_full_response_metadata() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.messageReceived(chatID: 4242,
                                           botVersion: "1.4.3",
                                           branch: "default",
                                           cannedResponse: false,
                                           sourcesCount: 2),
              on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_message_received"))
        #expect(properties["chat_id"] as? Int64 == 4242)
        #expect(properties["bot_version"] as? String == "1.4.3")
        #expect(properties["branch"] as? String == "default")
        #expect(properties["canned_response"] as? Bool == false)
        #expect(properties["sources_count"] as? Int == 2)
    }

    @Test func messageReceived_when_branch_is_nil_then_omits_branch_property() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.messageReceived(chatID: 4242,
                                           botVersion: "1.4.3",
                                           branch: nil,
                                           cannedResponse: true,
                                           sourcesCount: 0),
              on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_message_received"))
        #expect(properties["branch"] == nil)
        #expect(properties["canned_response"] as? Bool == true)
    }

    // MARK: - messageFailed

    @Test func messageFailed_emits_error_class_and_optional_status() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.messageFailed(errorClass: .rateLimit,
                                         httpStatus: 429,
                                         chatID: 4242),
              on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_message_failed"))
        #expect(properties["error_class"] as? String == "rate_limit")
        #expect(properties["http_status"] as? Int == 429)
        #expect(properties["chat_id"] as? Int64 == 4242)
    }

    @Test func messageFailed_when_no_status_then_omits_status_key() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.messageFailed(errorClass: .timeout,
                                         httpStatus: nil,
                                         chatID: nil),
              on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_message_failed"))
        #expect(properties["error_class"] as? String == "timeout")
        #expect(properties["http_status"] == nil)
        #expect(properties["chat_id"] == nil)
    }

    // MARK: - escalation

    @Test func forwardToHumanTriggered_carries_message_id_and_branch() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.forwardToHumanTriggered(chatID: 4242, messageID: 99, branch: "escalation"),
              on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_forward_to_human_triggered"))
        #expect(properties["chat_id"] as? Int64 == 4242)
        #expect(properties["message_id"] as? Int64 == 99)
        #expect(properties["branch"] as? String == "escalation")
    }

    @Test func contactHumanTapped_when_no_chat_id_then_omits_property() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.contactHumanTapped(chatID: nil), on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_contact_human_tapped"))
        #expect(properties["chat_id"] == nil)
    }

    // MARK: - closed

    @Test func closed_when_dismissed_with_no_chat_id_then_resolution_is_dismissed_no_message_sent() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.closed(chatID: nil,
                                  resolution: .dismissedNoMessageSent,
                                  messageCount: 0),
              on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_closed"))
        #expect(properties["resolution"] as? String == "dismissed_no_message_sent")
        #expect(properties["message_count"] as? Int == 0)
        #expect(properties["chat_id"] == nil)
    }

    @Test func closed_when_escalated_then_resolution_string_matches_contract() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.closed(chatID: 4242,
                                  resolution: .escalated,
                                  messageCount: 4),
              on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_closed"))
        #expect(properties["resolution"] as? String == "escalated")
        #expect(properties["chat_id"] as? Int64 == 4242)
        #expect(properties["message_count"] as? Int == 4)
    }

    // MARK: - history

    @Test func historyOpened_carries_chat_count() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.historyOpened(chatCount: 7), on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_history_opened"))
        #expect(properties["chat_count"] as? Int == 7)
    }

    @Test func historyResumed_carries_chat_id() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.historyResumed(chatID: 4242), on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_history_resumed"))
        #expect(properties["chat_id"] as? Int64 == 4242)
    }

    @Test func historyDeleted_carries_chat_id() {
        // Given
        let provider = MockAnalyticsProvider()

        // When
        track(.SupportChat.historyDeleted(chatID: 4242), on: provider)

        // Then
        let properties = try! #require(provider.properties(for: "support_chat_history_deleted"))
        #expect(properties["chat_id"] as? Int64 == 4242)
    }

}
