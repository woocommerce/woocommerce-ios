import Foundation
import Codegen

/// Details of a WordPress theme
///
public struct WordPressTheme: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// ID of the theme
    public let id: String

    /// Description of the theme
    public let description: String

    /// Name of the theme
    public let name: String

    /// URI of the demo site for the theme
    public let demoURI: String

    public init(id: String,
                description: String,
                name: String,
                demoURI: String) {
        self.id = id
        self.description = description
        self.name = name
        self.demoURI = demoURI
    }
}
