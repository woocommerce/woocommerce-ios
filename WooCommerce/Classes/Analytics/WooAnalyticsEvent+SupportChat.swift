import Foundation
import Yosemite
import protocol WooFoundation.WooAnalyticsEventPropertyType

extension WooAnalyticsEvent {
    enum SupportChat {
        enum TroubleshootingResult: String {
            case skipped
            case failed
            case passed
        }

        enum FeedbackRating: String {
            case up
            case down
        }

        enum EscalationSource: String {
            case toolbar
            case errorDialog
            case banner
        }

        enum EscalationTrigger: String {
            case errorDialog
            case manualToolbar
            case botForwardedToHumanSupport
        }

        enum TicketRoute: String {
            case supportForm
            case directTicketCreation
        }

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

        static func entryPointTapped(entryPoint: SupportChatViewModel.EntryPoint,
                                     isAuthenticated: Bool,
                                     isResumedChat: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatEntryPointTapped,
                              properties: [
                                Key.entryPoint.rawValue: entryPoint.analyticsValue,
                                Key.isAuthenticated.rawValue: isAuthenticated,
                                Key.isResumedChat.rawValue: isResumedChat
                              ])
        }

        static func issueSelected(issueType: SupportIssueType, entryPoint: SupportChatViewModel.EntryPoint) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatIssueSelected,
                              properties: [
                                Key.issueType.rawValue: issueType.analyticsValue,
                                Key.entryPoint.rawValue: entryPoint.analyticsValue
                              ])
        }

        static func troubleshootingCompleted(issueType: SupportIssueType,
                                             result: TroubleshootingResult,
                                             failedTest: SupportDiagnosticsService.Test? = nil) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Key.issueType.rawValue: issueType.analyticsValue,
                Key.result.rawValue: result.analyticsValue
            ]

            if let failedTest {
                properties[Key.failedTest.rawValue] = failedTest.analyticsValue
            }

            return WooAnalyticsEvent(statName: .supportChatTroubleshootingCompleted, properties: properties)
        }

        static func messageSent(entryPoint: SupportChatViewModel.EntryPoint,
                                isFirstMessage: Bool,
                                hasDiagnosticsContext: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatMessageSent,
                              properties: [
                                Key.entryPoint.rawValue: entryPoint.analyticsValue,
                                Key.isFirstMessage.rawValue: isFirstMessage,
                                Key.hasDiagnosticsContext.rawValue: hasDiagnosticsContext
                              ])
        }

        static func responseReceived(entryPoint: SupportChatViewModel.EntryPoint,
                                     supportArea: SupportChatSupportArea?,
                                     forwardToHumanSupport: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatResponseReceived,
                              properties: supportAreaProperties(for: supportArea).merging([
                                Key.entryPoint.rawValue: entryPoint.analyticsValue,
                                Key.hasChatTopic.rawValue: supportArea?.topic?.isNotEmpty == true,
                                Key.forwardToHumanSupport.rawValue: forwardToHumanSupport
                              ]) { _, new in new })
        }

        static func feedbackSubmitted(rating: FeedbackRating,
                                      entryPoint: SupportChatViewModel.EntryPoint,
                                      supportArea: SupportChatSupportArea?,
                                      userMessageCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatFeedbackSubmitted,
                              properties: supportAreaProperties(for: supportArea).merging([
                                Key.rating.rawValue: rating.analyticsValue,
                                Key.entryPoint.rawValue: entryPoint.analyticsValue,
                                Key.userMessageCount.rawValue: userMessageCount
                              ]) { _, new in new })
        }

        static func escalationButtonShown(trigger: EscalationTrigger,
                                          entryPoint: SupportChatViewModel.EntryPoint,
                                          supportArea: SupportChatSupportArea?,
                                          userMessageCount: Int? = nil) -> WooAnalyticsEvent {
            var properties = supportAreaProperties(for: supportArea)
            properties[Key.trigger.rawValue] = trigger.analyticsValue
            properties[Key.entryPoint.rawValue] = entryPoint.analyticsValue
            if let userMessageCount {
                properties[Key.userMessageCount.rawValue] = userMessageCount
            }
            return WooAnalyticsEvent(statName: .supportChatEscalationButtonShown, properties: properties)
        }

        static func escalationTapped(source: EscalationSource,
                                     entryPoint: SupportChatViewModel.EntryPoint,
                                     supportArea: SupportChatSupportArea?,
                                     userMessageCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatEscalationTapped,
                              properties: supportAreaProperties(for: supportArea).merging([
                                Key.source.rawValue: source.analyticsValue,
                                Key.entryPoint.rawValue: entryPoint.analyticsValue,
                                Key.userMessageCount.rawValue: userMessageCount
                              ]) { _, new in new })
        }

        static func ticketCreated(route: TicketRoute,
                                  supportAreaInfo: SupportAreaInfo?,
                                  entryPoint: SupportChatViewModel.EntryPoint) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatTicketCreated,
                              properties: ticketProperties(route: route, supportAreaInfo: supportAreaInfo, entryPoint: entryPoint))
        }

        static func ticketCreationFailed(route: TicketRoute,
                                         supportAreaInfo: SupportAreaInfo?,
                                         entryPoint: SupportChatViewModel.EntryPoint,
                                         errorType: String) -> WooAnalyticsEvent {
            var properties = ticketProperties(route: route, supportAreaInfo: supportAreaInfo, entryPoint: entryPoint)
            properties[Key.errorType.rawValue] = errorType
            return WooAnalyticsEvent(statName: .supportChatTicketCreationFailed, properties: properties)
        }

        static func resolutionButtonShown(entryPoint: SupportChatViewModel.EntryPoint,
                                          supportArea: SupportChatSupportArea?,
                                          userMessageCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .supportChatResolutionButtonShown,
                              properties: supportAreaProperties(for: supportArea).merging([
                                Key.entryPoint.rawValue: entryPoint.analyticsValue,
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
            Key.supportArea.rawValue: supportArea?.area.analyticsValue ?? Constants.unknown,
            Key.supportAreaConfidence.rawValue: supportArea?.confidence.analyticsValue ?? Constants.unknown
        ]
    }

    static func ticketProperties(route: TicketRoute,
                                 supportAreaInfo: SupportAreaInfo?,
                                 entryPoint: SupportChatViewModel.EntryPoint) -> [String: WooAnalyticsEventPropertyType] {
        var properties: [String: WooAnalyticsEventPropertyType] = [
            Key.route.rawValue: route.analyticsValue,
            Key.entryPoint.rawValue: entryPoint.analyticsValue,
            Key.supportArea.rawValue: supportAreaInfo?.areaType.analyticsValue ?? Constants.unknown,
            Key.supportAreaConfidence.rawValue: supportAreaInfo?.confidence.analyticsValue ?? Constants.unknown
        ]

        if let topic = supportAreaInfo?.topic, topic.isNotEmpty {
            properties[Key.chatTopic.rawValue] = topic
        }

        return properties
    }

    enum Constants {
        static let unknown = "unknown"
    }
}

private protocol AnalyticsSnakeCaseValue: RawRepresentable where RawValue == String {}

private extension SupportAreaType {
    var analyticsValue: String {
        rawValue
    }
}

private extension SupportAreaConfidence {
    var analyticsValue: String {
        rawValue
    }
}

private extension AnalyticsSnakeCaseValue {
    var analyticsValue: String {
        rawValue.analyticsSnakeCaseValue
    }
}

extension SupportChatViewModel.EntryPoint: AnalyticsSnakeCaseValue {}
extension SupportIssueType: AnalyticsSnakeCaseValue {}
extension SupportDiagnosticsService.Test: AnalyticsSnakeCaseValue {}
extension WooAnalyticsEvent.SupportChat.TroubleshootingResult: AnalyticsSnakeCaseValue {}
extension WooAnalyticsEvent.SupportChat.FeedbackRating: AnalyticsSnakeCaseValue {}
extension WooAnalyticsEvent.SupportChat.EscalationSource: AnalyticsSnakeCaseValue {}
extension WooAnalyticsEvent.SupportChat.EscalationTrigger: AnalyticsSnakeCaseValue {}
extension WooAnalyticsEvent.SupportChat.TicketRoute: AnalyticsSnakeCaseValue {}

private extension String {
    var analyticsSnakeCaseValue: String {
        reduce(into: "") { result, character in
            if character.isUppercase {
                if result.isNotEmpty {
                    result.append("_")
                }
                result.append(character.lowercased())
            } else {
                result.append(character)
            }
        }
    }
}
