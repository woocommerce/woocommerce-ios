import Foundation
import Yosemite

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

    private enum Localization {
        static let percentageDiscount = NSLocalizedString("Percentage Discount", comment: "Name of percentage discount type")
        static let fixedCartDiscount = NSLocalizedString("Fixed Cart Discount", comment: "Name of fixed cart discount type")
        static let fixedProductDiscount = NSLocalizedString("Fixed Product Discount", comment: "Name of fixed product discount type")
        static let otherDiscount = NSLocalizedString("Other", comment: "Generic name of non-default discount types")
    }
}

// MARK: - Coupon expiry status
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

        let result = calendar.compare(expiryDate, to: now, toGranularity: .day)
        return result == .orderedDescending ? .active : .expired
    }

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
            static let active = NSLocalizedString("Active", comment: "Status of coupons that are active")
            static let expired = NSLocalizedString("Expired", comment: "Status of coupons that are expired")
        }
    }
}

// MARK: - Sample Data
extension Coupon {
    static let sampleCoupon = Coupon(couponID: 720,
                                     code: "AGK32FD",
                                     amount: "10.00",
                                     dateCreated: Date(timeIntervalSinceNow: -1000),
                                     dateModified: Date(timeIntervalSinceNow: -1000),
                                     discountType: .fixedCart,
                                     description: "Coupon description",
                                     dateExpires: Date(timeIntervalSinceNow: 1000),
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
