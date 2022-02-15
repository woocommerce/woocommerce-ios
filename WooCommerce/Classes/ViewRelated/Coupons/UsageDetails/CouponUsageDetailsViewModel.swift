import Combine
import Foundation
import Yosemite

/// View Model for `CouponUsageDetails`
///
final class CouponUsageDetailsViewModel: ObservableObject {
    private let coupon: Coupon
    private let currencySettings: CurrencySettings

    var currencySymbol: String {
        currencySettings.symbol(from: currencySettings.currencyCode)
    }

    @Published private(set) var minimumSpend: String = ""

    @Published private(set) var maximumSpend: String = ""

    @Published private(set) var usageLimitPerCoupon: String = ""

    @Published private(set) var limitUsageToXItems: String = ""

    @Published private(set) var allowedEmails: String = ""

    @Published private(set) var individualUseOnly: Bool = false

    @Published private(set) var excludeSaleItems: Bool = false

    init(coupon: Coupon,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.coupon = coupon
        self.currencySettings = currencySettings
        populateDetails()
    }
}

// MARK: - Private helpers
//
private extension CouponUsageDetailsViewModel {
    func populateDetails() {
        minimumSpend = coupon.minimumAmount.isNotEmpty ? formatStringAmount(coupon.minimumAmount) : Localization.none
        maximumSpend = coupon.maximumAmount.isNotEmpty ? formatStringAmount(coupon.maximumAmount) : Localization.none
        if let usageLimit = coupon.usageLimit {
            usageLimitPerCoupon = "\(usageLimit)"
        } else {
            usageLimitPerCoupon = Localization.unlimited
        }

        if let limitUsageItemCount = coupon.limitUsageToXItems {
            limitUsageToXItems = "\(limitUsageItemCount)"
        } else {
            limitUsageToXItems = Localization.allQualifyingInCart
        }

        if coupon.emailRestrictions.isNotEmpty {
            allowedEmails = coupon.emailRestrictions.joined(separator: ", ")
        } else {
            allowedEmails = Localization.noRestrictions
        }

        individualUseOnly = coupon.individualUse
        excludeSaleItems = coupon.excludeSaleItems
    }

    func formatStringAmount(_ amount: String) -> String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        return currencyFormatter.formatAmount(amount) ?? ""
    }
}

// MARK: - Subtypes
//
private extension CouponUsageDetailsViewModel {
    enum Localization {
        static let none = NSLocalizedString("None", comment: "Value for fields in Coupon Usage Details screen when no value is set")
        static let unlimited = NSLocalizedString("Unlimited", comment: "Value for fields in Coupon Usage Details screen when no limit is set")
        static let allQualifyingInCart = NSLocalizedString(
            "All Qualifying in Cart",
            comment: "Value for the limit usage to X items row in Coupon Usage Details screen when no limit is set"
        )
        static let noRestrictions = NSLocalizedString(
            "No Restrictions",
            comment: "Value for the allowed emails row in Coupon Usage Details screen when no restriction is set"
        )
    }
}
