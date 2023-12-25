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

    public init(id: String, name: String) {
        self.id = id
        self.name = name
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
    public let parentLocation: BlazeTargetLocation?
}
