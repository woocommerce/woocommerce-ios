import Foundation
import Codegen

/// Represents a State Entity within a Country.
///
public struct StateOfACountry: Decodable, Equatable, Hashable, GeneratedFakeable {

    // E.g., ON for Ontario. Note: Not always two letters.
    public let code: String
    public let name: String

    /// StateOfACountry struct initializer.
    ///
    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }

    /// The public initializer for StateOfACountry.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let code = container.failsafeDecodeIfPresent(targetType: String.self,
                                                         forKey: .code,
                                                         alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })]) ?? ""
        let name = try container.decode(String.self, forKey: .name)

        self.init(code: code, name: name)
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
