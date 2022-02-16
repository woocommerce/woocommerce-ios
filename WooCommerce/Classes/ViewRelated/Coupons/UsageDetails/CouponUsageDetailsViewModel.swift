import Combine
import Foundation
import Yosemite

/// View Model for `CouponUsageDetails`
///
final class CouponUsageDetailsViewModel: ObservableObject {
    private let coupon: Coupon

    let currencySymbol: String

    @Published var minimumSpend: String = ""

    @Published var maximumSpend: String = ""

    @Published var usageLimitPerCoupon: String = ""

    @Published var usageLimitPerUser: String = ""

    @Published var limitUsageToXItems: String = ""

    @Published var allowedEmails: String = ""

    @Published var individualUseOnly: Bool = false

    @Published var excludeSaleItems: Bool = false

    init(coupon: Coupon,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.coupon = coupon
        self.currencySymbol = currencySettings.symbol(from: currencySettings.currencyCode)
        populateDetails()
    }
}

// MARK: - Private helpers
//
private extension CouponUsageDetailsViewModel {
    func populateDetails() {
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
}
