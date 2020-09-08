import Yosemite

extension ProductUpdateError {
    var alertTitle: String? {
        switch self {
        case .duplicatedSKU, .invalidSKU:
            return NSLocalizedString("Invalid Product SKU",
                                     comment: "The title of the alert when there is an error updating the product SKU")
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
        default:
            return nil
        }
    }
}
