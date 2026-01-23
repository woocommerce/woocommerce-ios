import Foundation
import Yosemite

/// Provides the relevant notice given an error after the Identifier scanned fails to provide an order item
///
struct BarcodeScannerErrorNoticeFactory {
    static func notice(for error: Error, code: ScannedBarcode, actionHandler: @escaping ((() -> Void))) -> Notice {
        Notice(title: Localization.defaultTitle,
               message: noticeMessage(for: error, code: code),
               feedbackType: .error,
               actionTitle: Localization.retryActionTitle,
               actionHandler: actionHandler)
    }

    private static func noticeMessage(for error: Error, code: ScannedBarcode) -> String {
        guard let productLoadError = error as? ProductLoadError else {
            return Localization.defaultTitle
        }

        switch productLoadError {
        case .notFound:
            return String(format: Localization.productNotFoundMessage, code.payloadStringValue)
        case .notPurchasable:
            return String(format: Localization.productNotPurchasableMessage, code.payloadStringValue)
        case .emptyIdentifier:
            return Localization.invalidIdentifier
        default:
            return Localization.defaultTitle
        }
    }
}

private extension BarcodeScannerErrorNoticeFactory {
    enum Localization {
        static let defaultTitle = NSLocalizedString("Cannot add Product to Order.",
                                                    comment: "This is an error message displayed as a notice title when a barcode scanner fails to add a scanned product to an order due to various reasons (product not found, not purchasable, or other generic errors).")
        static let invalidIdentifier = NSLocalizedString("Invalid Identifier",
                                                    comment: "Error when an empty Identifier is returned from the barcode scanner")
        static let productNotFoundMessage = NSLocalizedString("Product with Identifier \"%@\" not found.",
                                                            comment: "Error message when the scanner cannot find a matching product." +
                                                              "%@ is the Identifier barcode.")
        static let productNotPurchasableMessage = NSLocalizedString("Product with Identifier \"%@\" is not purchasable.",
                                                                  comment: "Error message when the scanner found a product but isn't purchasable." +
                                                                  "%@ is the Identifier code.")
        static let retryActionTitle = NSLocalizedString("Retry",
                                                          comment: "Retry button title when the scanner cannot find" +
                                                          "a matching product and create a new order")
    }
}
