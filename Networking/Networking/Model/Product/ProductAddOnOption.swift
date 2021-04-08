import Foundation

/// Represents a Product Add-On Option entity
///
public struct ProductAddOnOption: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    /// Option name.
    ///
    public let label: String?

    /// The price to charge when the option is selected.
    ///
    public let price: String?

    /// Option pricing type.
    ///
    public let priceType: AddOnPriceType?

    /// Option image id.
    ///
    public let imageID: Int64?

    public init(label: String?, price: String?, priceType: AddOnPriceType?, imageID: Int64?) {
        self.label = label
        self.price = price
        self.priceType = priceType
        self.imageID = imageID
    }

    // TODO: Make sure this is being parsed conditionally since fields can not be present
}
