import Yosemite

extension ProductUpdateError {
    var alertTitle: String? {
        switch self {
        case .duplicatedSKU, .invalidSKU:
            return NSLocalizedString("Invalid Product SKU",
                                     comment: "The title of the alert when there is an error updating the product SKU")
        case .variationInvalidImageId:
            return NSLocalizedString("Cannot update product",
                                     comment: "The title of the alert when there is an error removing the image from a Product Variation if WooCommerce <4.7")
        default:
            return nil
        }
    }
}

extension ProductUpdateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .duplicatedSKU:
            return NSLocalizedString("SKU already in use by another product",
                                     comment: "The message of the alert when there is an error updating the product SKU")
        case .invalidSKU:
            return NSLocalizedString("This SKU is used on another product or is invalid.",
                                     comment: "The message of the alert when there is an error updating the product SKU")
        case .unknown:
            return NSLocalizedString("Unexpected error", comment: "The message of the alert when there is an unexpected error updating the product")
        case .variationInvalidImageId:
            return NSLocalizedString("Sorry, image removal on product variations is supported in WooCommerce 4.7 or greater, please update your site.",
                                     comment: "The title of the alert when there is an error removing the image from a Product Variation if WooCommerce <4.7")
        default:
            return nil
        }
    }
}
