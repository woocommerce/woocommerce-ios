import Foundation
import Codegen


/// Represents Shipping Label Address that has been validated
///
public struct ShippingLabelAddressValidationSuccess: Equatable, GeneratedFakeable {
    public let address: ShippingLabelAddress

    /// When sending an address to normalize to the server, if the response has the is_trivial_normalization property set to true,
    /// then the normalized address will be automatically accepted without user intervention.
    /// As its name indicates, that flag will be set when the changes made by the address normalizator were trivial,
    /// such as adding the +4 portion to a ZIP code, or changing capitalization, or changing street to st for example.
    ///
    public let isTrivialNormalization: Bool

    public init(address: ShippingLabelAddress, isTrivialNormalization: Bool) {
        self.address = address
        self.isTrivialNormalization = isTrivialNormalization
    }
}
