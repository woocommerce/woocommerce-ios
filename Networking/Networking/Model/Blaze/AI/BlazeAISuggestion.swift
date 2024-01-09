import Foundation
import Codegen

public struct BlazeAISuggestion: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    /// Suggested tagline for the Blaze campaign.
    ///
    public let siteName: String

    /// Suggested description for the Blaze campaign.
    ///
    public let textSnippet: String

    public init(siteName: String, textSnippet: String) {
        self.siteName = siteName
        self.textSnippet = textSnippet
    }
}
