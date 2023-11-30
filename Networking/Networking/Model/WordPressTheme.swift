import Foundation
import Codegen

/// Details of a WordPress theme
///
public struct WordPressTheme: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// Name of the theme's author
    public let author: String

    /// ID of the theme
    public let id: String

    /// Description of the theme
    public let description: String

    /// Name of the theme
    public let name: String

    /// URI of the demo site for the theme
    public let demoURI: String

    public init(author: String,
                id: String,
                description: String,
                name: String,
                demoURI: String) {
        self.author = author
        self.id = id
        self.description = description
        self.name = name
        self.demoURI = demoURI
    }
}
