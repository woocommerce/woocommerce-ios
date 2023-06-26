import Foundation
import Yosemite

/// Provides the relevant notice given an error after the SKU scanned fails to provide an order item
/// 
struct BarcodeSKUScannerErrorNoticeFactory {
    static func notice(for error: Error, code: ScannedBarcode, actionHandler: @escaping ((() -> Void))) -> Notice {
        Notice(title: noticeTitle(for: error, code: code),
               feedbackType: .error,
               actionTitle: Localization.retryActionTitle,
               actionHandler: actionHandler)
    }

    private static func noticeTitle(for error: Error, code: ScannedBarcode) -> String {
        guard let productLoadError = error as? ProductLoadError else {
            return Localization.defaultTitle
        }

        switch productLoadError {
        case .notFound:
            return String(format: Localization.productNotFoundTitle, code.payloadStringValue)
        case .notPurchasable:
            return String(format: Localization.productNotPurchasableTitle, code.payloadStringValue)
        default:
            return Localization.defaultTitle
        }
    }
}

private extension BarcodeSKUScannerErrorNoticeFactory {
    enum Localization {
        static let defaultTitle = NSLocalizedString("Cannot add Product to Order.",
                                                    comment: "Generic error when a product can't be added to an order after being scanned.")
        static let productNotFoundTitle = NSLocalizedString("Product with SKU \"%@\" not found.",
                                                            comment: "Error message when the scanner cannot find a matching product. %@ is the SKU code.")
        static let productNotPurchasableTitle = NSLocalizedString("Product with SKU \"%@\" is not purchasable.",
                                                                  comment: "Error message when the scanner found a product but isn't purchasable." +
                                                                  "%@ is the SKU code.")
        static let retryActionTitle = NSLocalizedString("Retry",
                                                          comment: "Retry button title when the scanner cannot find" +
                                                          "a matching product and create a new order")
    }
}
