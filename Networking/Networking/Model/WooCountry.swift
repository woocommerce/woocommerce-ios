import Foundation
import Codegen

/// Represents a WooCountry Entity.
///
public struct WooCountry: Decodable, Equatable, GeneratedFakeable {

    // ISO-3166 two letter country code, e.g. CA for Canada
    public let code: String
    public let name: String
    public let states: [StateOfAWooCountry]

    /// WooCountry struct initializer.
    ///
    public init(code: String, name: String, states: [StateOfAWooCountry]) {
        self.code = code
        self.name = name
        self.states = states
    }
}


/// Defines all of the WooCountry's CodingKeys.
///
private extension WooCountry {

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case states
    }
}
