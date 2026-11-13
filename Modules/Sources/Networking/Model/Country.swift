import Foundation
import Codegen

/// Represents a Country Entity.
///
public struct Country: Decodable, Equatable, Hashable, GeneratedFakeable, Sendable {

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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let code = try container.decode(String.self, forKey: .code)
        // WooCommerce core sends some names HTML-encoded, e.g. `Cura&ccedil;ao`.
        let name = try container.decode(String.self, forKey: .name).strippedHTML
        let states = try container.decode([StateOfACountry].self, forKey: .states)

        self.init(code: code, name: name, states: states)
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
