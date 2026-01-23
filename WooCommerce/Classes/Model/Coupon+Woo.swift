import Foundation
import Yosemite
import UIKit
import WooFoundation

extension Coupon.DiscountType {
    /// Localized name to be displayed for the discount type.
    ///
    var localizedName: String {
        switch self {
        case .percent:
            return Localization.percentageDiscount
        case .fixedCart:
            return Localization.fixedCartDiscount
        case .fixedProduct:
            return Localization.fixedProductDiscount
        case .other:
            return Localization.otherDiscount
        }
    }

    /// Description to be displayed on the discount type list selector.
    ///
    var actionSheetDescription: String? {
        switch self {
        case .percent:
            return Localization.percentageDiscountDescription
        case .fixedCart:
            return Localization.fixedCartDiscountDescription
        case .fixedProduct:
            return Localization.fixedProductDiscountDescription
        case .other:
            return nil
        }
    }

    /// Image to be displayed on the discount type list selector
    ///
    var actionSheetIcon: UIImage? {
        switch self {
        case .percent:
            return UIImage.percentageDiscountIcon
        case .fixedCart:
            return UIImage.fixedCartDiscountIcon
        case .fixedProduct:
            return UIImage.fixedProductDiscountIcon
        case .other:
            return nil
        }
    }

    private enum Localization {
        static let percentageDiscount = NSLocalizedString("Percentage Discount", comment: "Name of percentage discount type")
        static let fixedCartDiscount = NSLocalizedString("Fixed Cart Discount", comment: "Name of fixed cart discount type")
        static let fixedProductDiscount = NSLocalizedString("Fixed Product Discount", comment: "Name of fixed product discount type")
        static let otherDiscount = NSLocalizedString("Other", comment: "Generic name of non-default discount types")
        static let percentageDiscountDescription = NSLocalizedString(
            "Create a percentage discount for selected products",
            comment: "Description for percentage discount type on the action sheet presented from Add or Edit coupon screen"
        )
        static let fixedCartDiscountDescription = NSLocalizedString(
            "Create a fixed total discount for the entire cart",
            comment: "Description for fixed cart discount type on the action sheet presented from Add or Edit coupon screen"
        )
        static let fixedProductDiscountDescription = NSLocalizedString(
            "Create a fixed total discount for selected products",
            comment: "Description for fixed product discount type on the action sheet presented from Add or Edit coupon screen"
        )
    }
}

// MARK: - Coupon details
//
extension Coupon {

    /// Expiry status for Coupons.
    ///
    func expiryStatus(now: Date = Date()) -> ExpiryStatus {
        guard let expiryDate = dateExpires else {
            return .active
        }

        guard let gmtTimeZone = TimeZone(identifier: "GMT") else {
            return .expired
        }

        var calendar = Calendar.current
        calendar.timeZone = gmtTimeZone

        // Compare the dates by minute to get around edge cases of timezone differences.
        let result = calendar.compare(expiryDate, to: now, toGranularity: .minute)
        return result == .orderedDescending ? .active : .expired
    }

    /// Summary line for the coupon
    ///
    func summary() -> String {
        return summary(currencySettings: ServiceLocator.currencySettings)
    }

    /// Formatted amount for the coupon
    ///
    func formattedAmount() -> String {
        return formattedAmount(currencySettings: ServiceLocator.currencySettings)
    }

    /// The message to be shared about the coupon
    ///
    func generateShareMessage(currencySettings: CurrencySettings) -> String {
        let formattedAmount = formattedAmount(currencySettings: currencySettings)
        let couponAmount = formattedAmount.isEmpty ? amount : formattedAmount
        if productIds.isNotEmpty ||
                   productCategories.isNotEmpty ||
                   excludedProductIds.isNotEmpty ||
                   excludedProductCategories.isNotEmpty {
            return String.localizedStringWithFormat(Localization.shareMessageSomeProducts, couponAmount, code)
        }
        return String.localizedStringWithFormat(Localization.shareMessageAllProducts, couponAmount, code)
    }
}

// MARK: - Subtypes
extension Coupon {
    /// Expiry status for coupons
    enum ExpiryStatus {
        case active
        case expired

        /// Localized name to be displayed for the expiry status.
        ///
        var localizedName: String {
            switch self {
            case .active:
                return Localization.active
            case .expired:
                return Localization.expired
            }
        }

        /// Text color for the expiry status label
        ///
        var statusForegroundColor: UIColor {
            .black
        }

        /// Background color for the expiry status label
        ///
        var statusBackgroundColor: UIColor {
            switch self {
            case .active:
                return .withColorStudio(.green, shade: .shade5)
            case .expired:
                return .gray(.shade5)
            }
        }

        private enum Localization {
            static let active = NSLocalizedString("Active", comment: "This text appears as a status label in three different contexts: indicating that coupons are currently valid and usable, showing that subscriptions are currently active and ongoing, and displaying the application's active state for debugging purposes.")
            static let expired = NSLocalizedString("Expired", comment: "Status of coupons that are expired")
        }
    }

    private enum Localization {
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

// MARK: - Sample Data
#if DEBUG
extension Coupon {
    static let sampleCoupon = Coupon(couponID: 720,
                                     code: "AGK32FD",
                                     amount: "10.00",
                                     dateCreated: Date(timeIntervalSinceNow: -1000),
                                     dateModified: Date(timeIntervalSinceNow: -1000),
                                     discountType: .fixedCart,
                                     description: "Coupon description",
                                     dateExpires: Date(timeIntervalSinceNow: 1000).startOfDay(timezone: TimeZone.current),
                                     usageCount: 10,
                                     individualUse: true,
                                     productIds: [],
                                     excludedProductIds: [12213],
                                     usageLimit: 1200,
                                     usageLimitPerUser: 3,
                                     limitUsageToXItems: 10,
                                     freeShipping: true,
                                     productCategories: [123, 435, 232],
                                     excludedProductCategories: [908],
                                     excludeSaleItems: false,
                                     minimumAmount: "5.00",
                                     maximumAmount: "500.00",
                                     emailRestrictions: ["*@a8c.com", "someone.else@example.com"],
                                     usedBy: ["someone.else@example.com", "person@a8c.com"])
}
#endif
