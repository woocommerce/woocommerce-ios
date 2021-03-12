import Foundation

/// Represents Shipping Label Address that should be verified.
///
public struct ShippingLabelAddressVerification: Equatable, GeneratedFakeable {
    public let address: ShippingLabelAddress?
    public let type: ShipType

    public init(address: ShippingLabelAddress?, type: ShipType) {
        self.address = address
        self.type = type
    }

    /// Represents all of the possible Type Statuses in enum form.
    /// It can be either be destination for the `Ship TO` address OR `origin` for the `Ship FROM` address.
    ///
    public enum ShipType: String, Encodable, Hashable, GeneratedFakeable {
        case origin
        case destination
    }
}

extension ShippingLabelAddressVerification: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encode(type, forKey: .type)
    }
}

/// Defines all of the ShippingLabelAddressVerification CodingKeys
///
private extension ShippingLabelAddressVerification {
    enum CodingKeys: String, CodingKey {
        case address
        case type
    }
}
