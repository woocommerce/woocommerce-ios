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
    public let imageID: String?

    public init(label: String?, price: String?, priceType: AddOnPriceType?, imageID: String?) {
        self.label = label
        self.price = price
        self.priceType = priceType
        self.imageID = imageID
    }
}

// MARK: Coding Keys
//
private extension ProductAddOnOption {
    enum CodingKeys: String, CodingKey {
        case label
        case price
        case priceType = "price_type"
        case imageID
    }
}
