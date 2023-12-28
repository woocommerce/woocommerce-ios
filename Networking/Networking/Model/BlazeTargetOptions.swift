import Codegen
import Foundation

/// Language to target for a Blaze campaign.
///
public struct BlazeTargetLanguage: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// ID of the language.
    public let id: String

    /// Name of the language
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// Device to target for a Blaze campaign.
///
public struct BlazeTargetDevice: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// ID of the device.
    public let id: String

    /// Name of the device
    public let name: String

    /// Locale of the device name
    public let locale: String

    public init(id: String, name: String, locale: String) {
        self.id = id
        self.name = name
        self.locale = locale
    }

    public enum CodingKeys: CodingKey {
        case id
        case name
        case locale
    }
    
    public init(from decoder: Decoder) throws {
        self.locale = decoder.userInfo[.locale] as? String ?? "en"
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
    }
}

/// Topic to target for a Blaze campaign.
///
public struct BlazeTargetTopic: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// ID of the topic.
    public let id: String

    /// Description of the topic.
    public let description: String

    public init(id: String, description: String) {
        self.id = id
        self.description = description
    }
}

/// Location to target for a Blaze campaign.
/// This has to be a class so that it can reference a property with the type of itself.
///
public final class BlazeTargetLocation: NSObject, Decodable, GeneratedCopiable, GeneratedFakeable {

    /// ID of the location
    public let id: Int64

    /// Name of the location
    public let name: String

    /// Type of the location
    public let type: String

    /// Post code of the location (if available)
    public let code: String?

    /// ISO code of the location (if available)
    public let isoCode: String?

    /// Parent of the location.
    /// "Parent" refers to the larger geographical context of a given location.
    /// For example the parent of a city is a state, or the parent of a country is a continent.
    public let parentLocation: BlazeTargetLocation?

    public init(id: Int64,
                name: String,
                type: String,
                code: String? = nil,
                isoCode: String? = nil,
                parentLocation: BlazeTargetLocation? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.code = code
        self.isoCode = isoCode
        self.parentLocation = parentLocation
    }
}
