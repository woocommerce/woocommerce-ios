import Foundation
import Yosemite
import protocol WooFoundation.WooAnalyticsEventPropertyType

extension WooAnalyticsEvent {
    enum SupportChat {
        private enum Key: String {
            case entryPoint = "entry_point"
            case isAuthenticated = "is_authenticated"
            case isResumedChat = "is_resumed_chat"
            case issueType = "issue_type"
            case result
            case failedTest = "failed_test"
            case isFirstMessage = "is_first_message"
            case hasDiagnosticsContext = "has_diagnostics_context"
            case supportArea = "support_area"
            case supportAreaConfidence = "support_area_confidence"
            case hasChatTopic = "has_chat_topic"
            case forwardToHumanSupport = "forward_to_human_support"
            case rating
            case chatTopic = "chat_topic"
            case userMessageCount = "user_message_count"
            case trigger
            case source
            case route
            case errorType = "error_type"
        }

        static func entryPointTapped(entryPoint: String,
                                     isAuthenticated: Bool,
                                     isResumedChat: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatEntryPointTapped,
                              properties: [
                                Key.entryPoint.rawValue: entryPoint,
                                Key.isAuthenticated.rawValue: isAuthenticated,
                                Key.isResumedChat.rawValue: isResumedChat
                              ])
        }

        static func issueSelected(issueType: String, entryPoint: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatIssueSelected,
                              properties: [
                                Key.issueType.rawValue: issueType,
                                Key.entryPoint.rawValue: entryPoint
                              ])
        }

        static func troubleshootingCompleted(issueType: String,
                                             result: String,
                                             failedTest: String? = nil) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Key.issueType.rawValue: issueType,
                Key.result.rawValue: result
            ]

            if let failedTest {
                properties[Key.failedTest.rawValue] = failedTest
            }

            return WooAnalyticsEvent(statName: .supportChatTroubleshootingCompleted, properties: properties)
        }

        static func messageSent(entryPoint: String,
                                isFirstMessage: Bool,
                                hasDiagnosticsContext: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatMessageSent,
                              properties: [
                                Key.entryPoint.rawValue: entryPoint,
                                Key.isFirstMessage.rawValue: isFirstMessage,
                                Key.hasDiagnosticsContext.rawValue: hasDiagnosticsContext
                              ])
        }

        static func responseReceived(entryPoint: String,
                                     supportArea: SupportChatSupportArea?,
                                     forwardToHumanSupport: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatResponseReceived,
                              properties: supportAreaProperties(for: supportArea).merging([
                                Key.entryPoint.rawValue: entryPoint,
                                Key.hasChatTopic.rawValue: supportArea?.topic?.isNotEmpty == true,
                                Key.forwardToHumanSupport.rawValue: forwardToHumanSupport
                              ]) { _, new in new })
        }

        static func feedbackSubmitted(rating: String,
                                      entryPoint: String,
                                      supportArea: SupportChatSupportArea?,
                                      userMessageCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatFeedbackSubmitted,
                              properties: supportAreaProperties(for: supportArea).merging([
                                Key.rating.rawValue: rating,
                                Key.entryPoint.rawValue: entryPoint,
                                Key.userMessageCount.rawValue: userMessageCount
                              ]) { _, new in new })
        }

        static func escalationButtonShown(trigger: String,
                                          entryPoint: String,
                                          supportArea: SupportChatSupportArea?,
                                          userMessageCount: Int? = nil) -> WooAnalyticsEvent {
            var properties = supportAreaProperties(for: supportArea)
            properties[Key.trigger.rawValue] = trigger
            properties[Key.entryPoint.rawValue] = entryPoint
            if let userMessageCount {
                properties[Key.userMessageCount.rawValue] = userMessageCount
            }
            return WooAnalyticsEvent(statName: .supportChatEscalationButtonShown, properties: properties)
        }

        static func escalationTapped(source: String,
                                     entryPoint: String,
                                     supportArea: SupportChatSupportArea?,
                                     userMessageCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatEscalationTapped,
                              properties: supportAreaProperties(for: supportArea).merging([
                                Key.source.rawValue: source,
                                Key.entryPoint.rawValue: entryPoint,
                                Key.userMessageCount.rawValue: userMessageCount
                              ]) { _, new in new })
        }

        static func ticketCreated(route: String,
                                  supportAreaInfo: SupportAreaInfo?,
                                  entryPoint: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatTicketCreated,
                              properties: ticketProperties(route: route, supportAreaInfo: supportAreaInfo, entryPoint: entryPoint))
        }

        static func ticketCreationFailed(route: String,
                                         supportAreaInfo: SupportAreaInfo?,
                                         entryPoint: String?,
                                         errorType: String) -> WooAnalyticsEvent {
            var properties = ticketProperties(route: route, supportAreaInfo: supportAreaInfo, entryPoint: entryPoint)
            properties[Key.errorType.rawValue] = errorType
            return WooAnalyticsEvent(statName: .supportChatTicketCreationFailed, properties: properties)
        }

        static func resolutionButtonShown(entryPoint: String,
                                          supportArea: SupportChatSupportArea?,
                                          userMessageCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatResolutionButtonShown,
                              properties: supportAreaProperties(for: supportArea).merging([
                                Key.entryPoint.rawValue: entryPoint,
                                Key.userMessageCount.rawValue: userMessageCount
                              ]) { _, new in new })
        }

        static func markResolvedTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatMarkResolvedTapped)
        }
    }
}

private extension WooAnalyticsEvent.SupportChat {
    static func supportAreaProperties(for supportArea: SupportChatSupportArea?) -> [String: WooAnalyticsEventPropertyType] {
        [
            Key.supportArea.rawValue: supportArea?.area.rawValue ?? Constants.unknown,
            Key.supportAreaConfidence.rawValue: supportArea?.confidence.rawValue ?? Constants.unknown
        ]
    }

    static func ticketProperties(route: String,
                                 supportAreaInfo: SupportAreaInfo?,
                                 entryPoint: String?) -> [String: WooAnalyticsEventPropertyType] {
        var properties: [String: WooAnalyticsEventPropertyType] = [
            Key.route.rawValue: route,
            Key.supportArea.rawValue: supportAreaInfo?.areaType.rawValue ?? Constants.unknown,
            Key.supportAreaConfidence.rawValue: supportAreaInfo?.confidence.rawValue ?? Constants.unknown
        ]

        if let entryPoint {
            properties[Key.entryPoint.rawValue] = entryPoint
        }

        if let topic = supportAreaInfo?.topic, topic.isNotEmpty {
            properties[Key.chatTopic.rawValue] = topic
        }

        return properties
    }

    enum Constants {
        static let unknown = "unknown"
    }
}
