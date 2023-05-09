import Foundation
import Codegen

/// Just In Time Message
/// Also referred to as JITM, these messages are triggered on a per WPcom user basis, and can be requested for particular contexts within the app.
/// They are generally displayed as a title, description, and Call To Action (CTA) button
///
public struct JustInTimeMessage: GeneratedCopiable, GeneratedFakeable, Equatable {
    /// Site Identifier
    ///
    public let siteID: Int64

    /// JITM id, e.g. `woomobile_ipp_barcode_users`. Identifies a message.
    ///
    public let messageID: String

    /// JITM feature class, groups JITMs by area, e.g. `woomobile_ipp`
    ///
    public let featureClass: String

    /// TTL, or Time To Live: validity of the JITM's client-side dismissal in seconds, only relevant after dismissal.
    ///
    public let ttl: Int64

    /// Content of the JITM: in particular, the title and description of the message
    ///
    public let content: Content

    /// CTA, or Call to Action: button details for the JITM: in particular, the button text and link to open
    ///
    public let cta: CTA

    /// Named assets for the JITM, with a URL string for where the asset can be found
    ///
    public let assets: [String: URL]

    public init(siteID: Int64,
                messageID: String,
                featureClass: String,
                ttl: Int64,
                content: JustInTimeMessage.Content,
                cta: JustInTimeMessage.CTA,
                assets: [String: URL]) {
        self.siteID = siteID
        self.messageID = messageID
        self.featureClass = featureClass
        self.ttl = ttl
        self.content = content
        self.cta = cta
        self.assets = assets
    }
}

extension JustInTimeMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case messageID = "id"
        case featureClass = "feature_class"
        case ttl
        case content
        case cta = "CTA"
        case assets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JustInTimeMessage.CodingKeys.self)

        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw JustInTimeMessageDecodingError.missingSiteID
        }

        self.siteID = siteID
        self.messageID = try container.decode(String.self, forKey: JustInTimeMessage.CodingKeys.messageID)
        self.featureClass = try container.decode(String.self, forKey: JustInTimeMessage.CodingKeys.featureClass)
        self.ttl = try container.decode(Int64.self, forKey: JustInTimeMessage.CodingKeys.ttl)
        self.content = try container.decode(JustInTimeMessage.Content.self, forKey: JustInTimeMessage.CodingKeys.content)
        self.cta = try container.decode(JustInTimeMessage.CTA.self, forKey: JustInTimeMessage.CodingKeys.cta)
        self.assets = try container.decodeIfPresent([String: URL].self, forKey: .assets) ?? [:]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JustInTimeMessage.CodingKeys.self)

        try container.encode(self.messageID, forKey: JustInTimeMessage.CodingKeys.messageID)
        try container.encode(self.featureClass, forKey: JustInTimeMessage.CodingKeys.featureClass)
        try container.encode(self.ttl, forKey: JustInTimeMessage.CodingKeys.ttl)
        try container.encode(self.content, forKey: JustInTimeMessage.CodingKeys.content)
        try container.encode(self.cta, forKey: JustInTimeMessage.CodingKeys.cta)
        try container.encode(self.assets, forKey: .assets)
    }
}

// MARK: - Nested Types
extension JustInTimeMessage {
    public struct Content: GeneratedCopiable, GeneratedFakeable, Codable, Equatable {
        /// The message is the title for a JITM – this is localized to the store's locale by WPcom, and intended to be shown to the user.
        ///
        public let message: String

        /// The message is the title for a JITM – this is localized to the store's locale by WPcom, and intended to be shown to the user.
        public let description: String

        enum CodingKeys: String, CodingKey {
            case message
            case description
        }

        public init(message: String, description: String) {
            self.message = message
            self.description = description
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JustInTimeMessage.Content.CodingKeys.self)

            self.message = try container.decode(String.self, forKey: JustInTimeMessage.Content.CodingKeys.message)
            self.description = try container.decode(String.self, forKey: JustInTimeMessage.Content.CodingKeys.description)

        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: JustInTimeMessage.Content.CodingKeys.self)

            try container.encode(self.message, forKey: JustInTimeMessage.Content.CodingKeys.message)
            try container.encode(self.description, forKey: JustInTimeMessage.Content.CodingKeys.description)
        }
    }

    public struct CTA: GeneratedCopiable, GeneratedFakeable, Codable, Equatable {
        /// The message is the button title for a JITM – this is localized to the store's locale by WPcom, and intended to be shown to the user.
        ///
        public let message: String

        /// The link to be opened when a JITM button is tapped. This may be a web link, or a deeplink.
        ///
        public let link: String

        enum CodingKeys: String, CodingKey {
            case message
            case link
        }

        public init(message: String, link: String) {
            self.message = message
            self.link = link
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JustInTimeMessage.CTA.CodingKeys.self)

            self.message = try container.decode(String.self, forKey: JustInTimeMessage.CTA.CodingKeys.message)
            self.link = try container.decode(String.self, forKey: JustInTimeMessage.CTA.CodingKeys.link)

        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: JustInTimeMessage.CTA.CodingKeys.self)

            try container.encode(self.message, forKey: JustInTimeMessage.CTA.CodingKeys.message)
            try container.encode(self.link, forKey: JustInTimeMessage.CTA.CodingKeys.link)
        }
    }
}

// MARK: - Decoding Errors
//
enum JustInTimeMessageDecodingError: Error {
    case missingSiteID
}
