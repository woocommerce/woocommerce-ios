import Yosemite

extension ProductUpdateError {
    var alertTitle: String? {
        switch self {
        case .invalidSKU:
            return NSLocalizedString("Invalid Product SKU",
                                     comment: "The title of the alert when there is an error updating the product SKU")
        default:
            return nil
        }
    }

    var alertMessage: String? {
        switch self {
        case .invalidSKU:
            return NSLocalizedString("This SKU is used on another product or is invalid.",
                                     comment: "The message of the alert when there is an error updating the product SKU")
        default:
            return nil
        }
    }
}
