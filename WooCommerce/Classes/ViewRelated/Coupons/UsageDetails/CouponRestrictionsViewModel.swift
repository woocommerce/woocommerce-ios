import Combine
import Foundation
import Yosemite

/// View Model for `CouponRestriction`
///
final class CouponRestrictionsViewModel: ObservableObject {

    let currencySymbol: String

    @Published var minimumSpend: String

    @Published var maximumSpend: String

    @Published var usageLimitPerCoupon: String

    @Published var usageLimitPerUser: String

    @Published var limitUsageToXItems: String

    @Published var allowedEmails: String

    @Published var individualUseOnly: Bool

    @Published var excludeSaleItems: Bool

    init(coupon: Coupon,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        currencySymbol = currencySettings.symbol(from: currencySettings.currencyCode)

        minimumSpend = coupon.minimumAmount
        maximumSpend = coupon.maximumAmount
        if let perCoupon = coupon.usageLimit {
            usageLimitPerCoupon = "\(perCoupon)"
        } else {
            usageLimitPerCoupon = ""
        }

        if let perUser = coupon.usageLimitPerUser {
            usageLimitPerUser = "\(perUser)"
        } else {
            usageLimitPerUser = ""
        }

        if let limitUsageItemCount = coupon.limitUsageToXItems {
            limitUsageToXItems = "\(limitUsageItemCount)"
        } else {
            limitUsageToXItems = ""
        }

        if coupon.emailRestrictions.isNotEmpty {
            allowedEmails = coupon.emailRestrictions.joined(separator: ", ")
        } else {
            allowedEmails = ""
        }

        individualUseOnly = coupon.individualUse
        excludeSaleItems = coupon.excludeSaleItems
    }

    init(currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        currencySymbol = currencySettings.symbol(from: currencySettings.currencyCode)
        minimumSpend = ""
        maximumSpend = ""
        usageLimitPerCoupon = ""
        usageLimitPerUser = ""
        limitUsageToXItems = ""
        allowedEmails = ""
        individualUseOnly = false
        excludeSaleItems = false
    }
}
