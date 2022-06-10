import Foundation
import Yosemite

extension Coupon {
    /// The message to be shared about the coupon
    ///
    func generateShareMessage(couponAmount: String) -> String {
        if productIds.isNotEmpty ||
                   productCategories.isNotEmpty ||
                   excludedProductIds.isNotEmpty ||
                   excludedProductCategories.isNotEmpty {
            return String.localizedStringWithFormat(Localization.shareMessageSomeProducts, couponAmount, code)
        }
        return String.localizedStringWithFormat(Localization.shareMessageAllProducts, couponAmount, code)
    }
}

private extension Coupon {
    enum Localization {
        static let shareMessageAllProducts = NSLocalizedString(
                "Apply %1$@ off to all products with the promo code “%2$@”.",
                comment: "Message to share the coupon code if it is applicable to all products. " +
                        "Reads like: Apply 10% off to all products with the promo code “20OFF”.")
        static let shareMessageSomeProducts = NSLocalizedString(
                "Apply %1$@ off to some products with the promo code “%2$@”.",
                comment: "Message to share the coupon code if it is applicable to some products. " +
                        "Reads like: Apply 10% off to some products with the promo code “20OFF”.")
    }
}
