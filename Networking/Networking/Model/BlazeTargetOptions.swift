import Foundation

/// Language to target for a Blaze campaign.
///
public struct BlazeTargetLanguage: Decodable, Equatable {

    /// ID of the language.
    public let id: String

    /// Name of the language
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
