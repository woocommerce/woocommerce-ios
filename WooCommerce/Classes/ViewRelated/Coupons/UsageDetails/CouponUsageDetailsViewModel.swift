import Combine
import Foundation
import Yosemite

/// View Model for `CouponUsageDetails`
///
final class CouponUsageDetailsViewModel: ObservableObject {
    private let coupon: Coupon

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
        self.coupon = coupon
        self.currencySymbol = currencySettings.symbol(from: currencySettings.currencyCode)

        self.minimumSpend = coupon.minimumAmount
        self.maximumSpend = coupon.maximumAmount
        if let perCoupon = coupon.usageLimit {
            self.usageLimitPerCoupon = "\(perCoupon)"
        } else {
            self.usageLimitPerCoupon = ""
        }

        if let perUser = coupon.usageLimitPerUser {
            self.usageLimitPerUser = "\(perUser)"
        } else {
            self.usageLimitPerUser = ""
        }

        if let limitUsageItemCount = coupon.limitUsageToXItems {
            self.limitUsageToXItems = "\(limitUsageItemCount)"
        } else {
            self.limitUsageToXItems = ""
        }

        if coupon.emailRestrictions.isNotEmpty {
            self.allowedEmails = coupon.emailRestrictions.joined(separator: ", ")
        } else {
            self.allowedEmails = ""
        }

        self.individualUseOnly = coupon.individualUse
        self.excludeSaleItems = coupon.excludeSaleItems
    }
}
