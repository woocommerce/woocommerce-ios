import Foundation
import Codegen

/// Represents a State Entity within a StateOfAWooCountry.
///
public struct StateOfAWooCountry: Decodable, Equatable, GeneratedFakeable {

    // E.g., ON for Ontario. Note: Not always two letters.
    public let code: String
    public let name: String

    /// StateOfAWooCountry struct initializer.
    ///
    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }
}


/// Defines all of the StateOfAWooCountry's CodingKeys.
///
private extension StateOfAWooCountry {

    enum CodingKeys: String, CodingKey {
        case code
        case name
    }
}
