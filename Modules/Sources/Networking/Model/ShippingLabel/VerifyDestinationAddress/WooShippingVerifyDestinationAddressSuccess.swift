import Foundation
import Codegen

/// Represents Shipping Label Destination Address that has been verified by the WooCommerce Shipping extension.
///
public struct WooShippingVerifyDestinationAddressSuccess: Equatable {
    public let normalizedAddress: WooShippingNormalizedAddress

    /// Optional property -  We will receive this property in response only when the address is not already verified.
    ///
    /// When sending an address to normalize to the server, if the response has the is_trivial_normalization property set to true,
    /// then the normalized address will be automatically accepted without user intervention.
    /// As its name indicates, that flag will be set when the changes made by the address normalizator were trivial,
    /// such as adding the +4 portion to a ZIP code, or changing capitalization, or changing street to st for example.
    ///
    public let isTrivialNormalization: Bool?

    public let isVerified: Bool

    public init(normalizedAddress: WooShippingNormalizedAddress,
                isTrivialNormalization: Bool?,
                isVerified: Bool) {
        self.normalizedAddress = normalizedAddress
        self.isTrivialNormalization = isTrivialNormalization
        self.isVerified = isVerified
    }
}
