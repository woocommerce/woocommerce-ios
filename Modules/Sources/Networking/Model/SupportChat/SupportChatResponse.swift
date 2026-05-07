import Foundation

/// A conversation with a support chat assistant.
///
/// Response shape returned by `POST /wpcom/v2/odie/chat/{bot_slug}` and its follow-up
/// endpoint `/wpcom/v2/odie/chat/{bot_slug}/{chat_id}`. Each POST returns the thread
/// with any new bot messages appended to `messages`.
///
public struct SupportChatResponse: Decodable, Equatable {
    public let chatID: Int64
    public let sessionID: String
    public let botSlug: String
    public let botVersion: String
    public let messages: [SupportChatMessage]

    public init(chatID: Int64,
                sessionID: String,
                botSlug: String,
                botVersion: String,
                messages: [SupportChatMessage]) {
        self.chatID = chatID
        self.sessionID = sessionID
        self.botSlug = botSlug
        self.botVersion = botVersion
        self.messages = messages
    }

    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case sessionID = "session_id"
        case botSlug = "bot_slug"
        case botVersion = "bot_version"
        case messages
    }
}

/// Role of a message sender in a support chat thread.
///
public enum SupportChatRole: String, Decodable, Equatable {
    case bot
    case user
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SupportChatRole(rawValue: rawValue) ?? .unknown
    }
}

/// A single message in a chat thread.
///
public struct SupportChatMessage: Decodable, Equatable {
    public let messageID: Int64
    public let role: SupportChatRole
    public let content: String
    public let context: SupportChatMessageContext?

    public init(messageID: Int64,
                role: SupportChatRole,
                content: String,
                context: SupportChatMessageContext?) {
        self.messageID = messageID
        self.role = role
        self.content = content
        self.context = context
    }

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case role
        case content
        case context
    }
}

/// Per-message metadata attached by the bot: RAG sources + routing/branch flags.
///
public struct SupportChatMessageContext: Decodable, Equatable {
    public let sources: [SupportChatSource]
    public let flags: SupportChatFlags?
    public let supportArea: SupportChatSupportArea?

    public init(sources: [SupportChatSource], flags: SupportChatFlags?, supportArea: SupportChatSupportArea? = nil) {
        self.sources = sources
        self.flags = flags
        self.supportArea = supportArea
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sources = (try? container.decode([SupportChatSource].self, forKey: .sources)) ?? []
        self.flags = try? container.decode(SupportChatFlags.self, forKey: .flags)
        self.supportArea = try? container.decode(SupportChatSupportArea.self, forKey: .supportArea)
    }

    enum CodingKeys: String, CodingKey {
        case sources
        case flags
        case supportArea = "support_area"
    }
}

/// A source document cited by the bot (RAG grounding).
///
public struct SupportChatSource: Decodable, Equatable {
    public let title: String
    public let url: String
    public let heading: String?
    public let content: String?

    public init(title: String, url: String, heading: String?, content: String?) {
        self.title = title
        self.url = url
        self.heading = heading
        self.content = content
    }
}

/// Confidence level for support area classification.
///
public enum SupportAreaConfidence: String, Decodable, Equatable {
    case high
    case medium
    case low

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SupportAreaConfidence(rawValue: rawValue.lowercased()) ?? .low
    }
}

/// Support area categories for ticket routing.
///
public enum SupportAreaType: String, Decodable, Equatable {
    case mobileApp = "mobile-app"
    case cardReader = "card-reader"
    case wooPayments = "woopayments"
    case wooCommercePlugin = "woocommerce-plugin"
    case otherExtensionPlugin = "other-extension-plugin"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SupportAreaType(rawValue: rawValue.lowercased()) ?? .mobileApp
    }
}

/// Support area classification returned by the bot for ticket routing.
///
public struct SupportChatSupportArea: Decodable, Equatable {
    public let area: SupportAreaType
    public let confidence: SupportAreaConfidence

    public var isHighConfidence: Bool {
        confidence == .high
    }

    public init(area: SupportAreaType, confidence: SupportAreaConfidence) {
        self.area = area
        self.confidence = confidence
    }
}

/// Routing / state flags returned alongside a bot message.
///
public struct SupportChatFlags: Decodable, Equatable {
    public let forwardToHumanSupport: Bool
    public let cannedResponse: Bool
    public let loggedIn: Bool
    public let branch: String?

    public init(forwardToHumanSupport: Bool,
                cannedResponse: Bool,
                loggedIn: Bool,
                branch: String?) {
        self.forwardToHumanSupport = forwardToHumanSupport
        self.cannedResponse = cannedResponse
        self.loggedIn = loggedIn
        self.branch = branch
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.forwardToHumanSupport = (try? container.decode(Bool.self, forKey: .forwardToHumanSupport)) ?? false
        self.cannedResponse = (try? container.decode(Bool.self, forKey: .cannedResponse)) ?? false
        self.loggedIn = (try? container.decode(Bool.self, forKey: .loggedIn)) ?? false
        self.branch = try? container.decode(String.self, forKey: .branch)
    }

    enum CodingKeys: String, CodingKey {
        case forwardToHumanSupport = "forward_to_human_support"
        case cannedResponse = "canned_response"
        case loggedIn = "logged_in"
        case branch
    }
}
