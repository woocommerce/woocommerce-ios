import Foundation

public struct AssistantTelemetryContext: Equatable, Sendable {
    public let conversationID: String
    public let requestID: String
    public let messageID: String

    public init(conversationID: String, requestID: String, messageID: String) {
        self.conversationID = conversationID
        self.requestID = requestID
        self.messageID = messageID
    }
}
