import Foundation
import Codegen

/// Represents a Country Entity.
///
public struct Country: Decodable, Equatable, Hashable, GeneratedFakeable {

    // ISO-3166 two letter country code, e.g. CA for Canada
    public let code: String
    public let name: String
    public let states: [StateOfACountry]

    /// Country struct initializer.
    ///
    public init(code: String, name: String, states: [StateOfACountry]) {
        self.code = code
        self.name = name
        self.states = states
    }
}


/// Defines all of the Country's CodingKeys.
///
private extension Country {

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case states
    }
}
