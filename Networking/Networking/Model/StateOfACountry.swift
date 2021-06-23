import Foundation
import Codegen

/// Represents a State Entity within a Country.
///
public struct StateOfACountry: Decodable, Equatable, GeneratedFakeable {
    public let code: String
    public let name: String

    /// StateOfACountry struct initializer.
    ///
    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }
}


/// Defines all of the StateOfACountry's CodingKeys.
///
private extension StateOfACountry {

    enum CodingKeys: String, CodingKey {
        case code
        case name
    }
}
