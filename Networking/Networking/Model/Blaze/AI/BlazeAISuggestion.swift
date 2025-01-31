import Foundation
import Codegen

public struct BlazeAISuggestion: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    /// Suggested tagline for the Blaze campaign.
    ///
    public let siteName: String

    /// Suggested description for the Blaze campaign.
    ///
    public let textSnippet: String

    /// Suggested CTA for the Blaze campaign.
    ///
    public let ctaText: String

    public init(siteName: String, textSnippet: String, ctaText: String) {
        self.siteName = siteName
        self.textSnippet = textSnippet
        self.ctaText = ctaText
    }
}
