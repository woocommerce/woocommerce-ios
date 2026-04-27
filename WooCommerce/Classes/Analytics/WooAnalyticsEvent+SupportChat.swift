import Foundation
import protocol WooFoundation.WooAnalyticsEventPropertyType

extension WooAnalyticsEvent {

    /// Analytics events for the AI support chat feature.
    ///
    enum SupportChat {

        /// Where the chat was launched from. Repeated across `opened` / `message_sent`
        /// so the funnel is partitionable without joining on session ID.
        ///
        enum EntryPoint: String {
            case connectivityTool = "connectivity_tool"
            case helpSettings = "help_settings"
            case preLogin = "pre_login"
        }

        /// Auth context at the time of the event. Drives rate-limit segmentation.
        ///
        enum AuthState: String {
            case preLogin = "pre_login"
            case wpcom
            case jetpack
            case appPassword = "app_password"
        }

        /// How the chat ended. Used for `support_chat_closed`.
        ///
        enum Resolution: String {
            case completed
            case escalated
            case dismissedNoMessageSent = "dismissed_no_message_sent"
        }

        /// Bucketed error class for `support_chat_message_failed`. Avoids dumping raw
        /// server messages (which can carry site context).
        ///
        enum ErrorClass: String {
            case timeout
            case decoding
            case network
            case rateLimit = "rate_limit"
            case unauthorized
            case server
            case unknown
        }

        // MARK: - Property keys

        private enum Keys {
            static let entryPoint = "entry_point"
            static let authState = "auth_state"
            static let chatResumed = "chat_resumed"
            static let chatID = "chat_id"
            static let botVersion = "bot_version"
            static let branch = "branch"
            static let cannedResponse = "canned_response"
            static let sourcesCount = "sources_count"
            static let errorClass = "error_class"
            static let httpStatus = "http_status"
            static let messageID = "message_id"
            static let sourceScore = "source_score"
            static let ratingValue = "rating_value"
            static let resolution = "resolution"
            static let messageCount = "message_count"
            static let chatCount = "chat_count"
        }

        // MARK: - Entry

        static func opened(entryPoint: EntryPoint,
                           authState: AuthState,
                           chatResumed: Bool) -> WooAnalyticsEvent {
            .init(statName: .supportChatOpened,
                  properties: [
                    Keys.entryPoint: entryPoint.rawValue,
                    Keys.authState: authState.rawValue,
                    Keys.chatResumed: chatResumed
                  ])
        }

        // MARK: - Conversation

        /// Note: first-turn vs follow-up is derivable from `chat_id` (nil = first turn).
        static func messageSent(chatID: Int64?,
                                entryPoint: EntryPoint) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.entryPoint: entryPoint.rawValue
            ]
            if let chatID {
                properties[Keys.chatID] = chatID
            }
            return .init(statName: .supportChatMessageSent, properties: properties)
        }

        static func messageReceived(chatID: Int64,
                                    botVersion: String,
                                    branch: String?,
                                    cannedResponse: Bool,
                                    sourcesCount: Int) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.chatID: chatID,
                Keys.botVersion: botVersion,
                Keys.cannedResponse: cannedResponse,
                Keys.sourcesCount: sourcesCount
            ]
            if let branch {
                properties[Keys.branch] = branch
            }
            return .init(statName: .supportChatMessageReceived, properties: properties)
        }

        static func messageFailed(errorClass: ErrorClass,
                                  httpStatus: Int?,
                                  chatID: Int64?) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.errorClass: errorClass.rawValue
            ]
            if let httpStatus {
                properties[Keys.httpStatus] = httpStatus
            }
            if let chatID {
                properties[Keys.chatID] = chatID
            }
            return .init(statName: .supportChatMessageFailed, properties: properties)
        }

        // MARK: - Sources

        static func sourceTapped(chatID: Int64,
                                 messageID: Int64,
                                 sourceScore: Double) -> WooAnalyticsEvent {
            .init(statName: .supportChatSourceTapped,
                  properties: [
                    Keys.chatID: chatID,
                    Keys.messageID: messageID,
                    Keys.sourceScore: sourceScore
                  ])
        }

        // MARK: - Feedback

        static func feedbackSubmitted(chatID: Int64,
                                      messageID: Int64,
                                      ratingValue: Int) -> WooAnalyticsEvent {
            .init(statName: .supportChatFeedbackSubmitted,
                  properties: [
                    Keys.chatID: chatID,
                    Keys.messageID: messageID,
                    Keys.ratingValue: ratingValue
                  ])
        }

        // MARK: - Escalation

        static func forwardToHumanTriggered(chatID: Int64,
                                            messageID: Int64,
                                            branch: String?) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.chatID: chatID,
                Keys.messageID: messageID
            ]
            if let branch {
                properties[Keys.branch] = branch
            }
            return .init(statName: .supportChatForwardToHumanTriggered, properties: properties)
        }

        static func contactHumanTapped(chatID: Int64?) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [:]
            if let chatID {
                properties[Keys.chatID] = chatID
            }
            return .init(statName: .supportChatContactHumanTapped, properties: properties)
        }

        // MARK: - Closure

        static func closed(chatID: Int64?,
                           resolution: Resolution,
                           messageCount: Int) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.resolution: resolution.rawValue,
                Keys.messageCount: messageCount
            ]
            if let chatID {
                properties[Keys.chatID] = chatID
            }
            return .init(statName: .supportChatClosed, properties: properties)
        }

        // MARK: - History

        static func historyOpened(chatCount: Int) -> WooAnalyticsEvent {
            .init(statName: .supportChatHistoryOpened,
                  properties: [Keys.chatCount: chatCount])
        }

        static func historyResumed(chatID: Int64) -> WooAnalyticsEvent {
            .init(statName: .supportChatHistoryResumed,
                  properties: [Keys.chatID: chatID])
        }

        static func historyDeleted(chatID: Int64) -> WooAnalyticsEvent {
            .init(statName: .supportChatHistoryDeleted,
                  properties: [Keys.chatID: chatID])
        }
    }
}
