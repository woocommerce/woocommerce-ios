import Foundation

/// Represents Shipping Label Custom Package that should be created.
///
public struct ShippingLabelCustomPackageCreation {
    public let customPackage: [ShippingLabelCustomPackage]

    public init(customPackage: [ShippingLabelCustomPackage]) {
        self.customPackage = customPackage
    }
}

extension ShippingLabelCustomPackageCreation: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(customPackage, forKey: .custom)
    }
}

/// Defines all of the ShippingLabelAddressVerification CodingKeys
///
private extension ShippingLabelCustomPackageCreation {
    enum CodingKeys: String, CodingKey {
        case custom
    }
}
