import Foundation
import Codegen

/// Represents a Dimensions Entity.
///
public struct ProductDimensions: Codable, Equatable, GeneratedFakeable {
    public let length: String
    public let width: String
    public let height: String

    /// Dimension struct initializer.
    ///
    public init(length: String,
                width: String,
                height: String) {
        self.length = length
        self.width = width
        self.height = height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Even though a plain install of WooCommerce Core provides String dimension values,
        // some plugins may alter the field values from String to Int or Decimal.
        let length = container.failsafeDecodeIfPresent(targetType: String.self,
                                                       forKey: .length,
                                                       alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })]) ?? ""
        let width = container.failsafeDecodeIfPresent(targetType: String.self,
                                                      forKey: .width,
                                                      alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })]) ?? ""
        let height = container.failsafeDecodeIfPresent(targetType: String.self,
                                                       forKey: .height,
                                                       alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })]) ?? ""

        self.init(length: length, width: width, height: height)
    }
}

/// Defines all of the Dimensions CodingKeys
///
private extension ProductDimensions {

    enum CodingKeys: String, CodingKey {
        case length
        case width
        case height
    }
}
