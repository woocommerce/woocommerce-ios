import Foundation
import Yosemite

/// View model for `CouponDetails` view
///
final class CouponDetailsViewModel: ObservableObject {
    let siteID: Int64

    /// Code of the coupon
    ///
    @Published private(set) var couponCode: String = ""

    /// Description of the coupon
    ///
    @Published private(set) var description: String = ""

    /// Discount type of the coupon
    ///
    @Published private(set) var discountType: String = ""

    /// Amount of the coupon
    ///
    @Published private(set) var amount: String = ""

    /// Number of times this coupon be used per customer
    @Published private(set) var usageLimitPerUser: Int64?

    /// If `true`, this coupon will not be applied to items that have sale prices
    ///
    @Published private(set) var excludeSaleItems: Bool = false

    /// Minimum order amount that needs to be in the cart before coupon applies
    ///
    @Published private(set) var minimumAmount: String = ""

    /// Maximum order amount allowed when using the coupon
    /// 
    @Published private(set) var maximumAmount: String = ""

    /// Whether the coupon should provide free shipping
    ///
    @Published private(set) var allowsFreeShipping: Bool = false

    /// Email addresses of customers who are allowed to use this coupon, which may include * as wildcard
    ///
    @Published private(set) var emailRestrictions: [String] = []

    /// Summary of the coupon
    ///
    @Published private(set) var summary: String = ""

    /// Expiry date of the coupon
    ///
    @Published private(set) var expiryDate: String = ""

    /// Indicates if loading total discounted amount fails
    ///
    @Published private(set) var hasErrorLoadingAmount: Bool = false

    /// Indicates if WC Analytics is disabled for this store
    ///
    @Published private(set) var hasWCAnalyticsDisabled: Bool = false

    /// The message to be shared about the coupon
    ///
    var shareMessage: String {
        if coupon.productIds.isNotEmpty ||
            coupon.productCategories.isNotEmpty ||
            coupon.excludedProductIds.isNotEmpty ||
            coupon.excludedProductCategories.isNotEmpty {
            return String.localizedStringWithFormat(Localization.shareMessageSomeProducts, amount, couponCode)
        }
        return String.localizedStringWithFormat(Localization.shareMessageAllProducts, amount, couponCode)
    }

    /// Total number of orders that applied the coupon
    ///
    @Published private(set) var discountedOrdersCount: String = "0"

    /// Total amount deducted from orders that applied the coupon
    ///
    @Published private(set) var discountedAmount: String?

    /// The current coupon
    ///
    @Published private(set) var coupon: Coupon {
        didSet {
            populateDetails()
        }
    }

    var shouldShowErrorLoadingAmount: Bool {
        (hasErrorLoadingAmount || hasWCAnalyticsDisabled) && discountedAmount == nil
    }

    private let stores: StoresManager
    private let currencySettings: CurrencySettings

    init(coupon: Coupon,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = coupon.siteID
        self.coupon = coupon
        self.stores = stores
        self.currencySettings = currencySettings
        populateDetails()
    }

    func syncCoupon() {
        let action = CouponAction.retrieveCoupon(siteID: coupon.siteID, couponID: coupon.couponID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let coupon):
                self.coupon = coupon
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing coupon detail: \(error)")
            }
        }
        stores.dispatch(action)
    }

    func loadCouponReport() {
        // Reset error states
        hasWCAnalyticsDisabled = false
        hasErrorLoadingAmount = false
        // Get "ancient" date to fetch all possible reports
        let startDate = Date(timeIntervalSince1970: 1)
        let action = CouponAction.loadCouponReport(siteID: siteID, couponID: coupon.couponID, startDate: startDate) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let report):
                self.discountedOrdersCount = "\(report.ordersCount)"
                self.discountedAmount = self.formatStringAmount("\(report.amount)")
                self.hasErrorLoadingAmount = false
            case .failure(let error):
                DDLogError("⛔️ Error loading coupon report: \(error)")

                self.retrieveAnalyticsSetting { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let isEnabled):
                        if isEnabled {
                            self.hasErrorLoadingAmount = true
                        } else {
                            self.hasWCAnalyticsDisabled = true
                        }
                    case .failure(let error):
                        DDLogError("⛔️ Error retrieving analytics setting: \(error)")
                        self.hasErrorLoadingAmount = true
                    }
                }
            }
        }
        stores.dispatch(action)
    }
}

// MARK: - Private helpers
//
private extension CouponDetailsViewModel {

    func populateDetails() {
        couponCode = coupon.code
        discountType = coupon.discountType.localizedName
        description = coupon.description
        discountedOrdersCount = "\(coupon.usageCount)"
        if coupon.usageCount == 0 {
            discountedAmount = formatStringAmount("0")
        }

        let formattedAmount = coupon.formattedAmount(currencySettings: currencySettings)
        amount = formattedAmount.isEmpty ? coupon.amount : formattedAmount
        summary = coupon.summary(currencySettings: currencySettings)

        expiryDate = coupon.dateExpires?.toString(dateStyle: .long, timeStyle: .none) ?? ""
        usageLimitPerUser = coupon.usageLimitPerUser
        excludeSaleItems = coupon.excludeSaleItems
        minimumAmount = formatStringAmount(coupon.minimumAmount)
        maximumAmount = formatStringAmount(coupon.maximumAmount)
        allowsFreeShipping = coupon.freeShipping
        emailRestrictions = coupon.emailRestrictions
    }

    func formatStringAmount(_ amount: String) -> String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        return currencyFormatter.formatAmount(amount) ?? ""
    }

    func retrieveAnalyticsSetting(completion: @escaping (Result<Bool, Error>) -> Void) {
        let action = SettingAction.retrieveAnalyticsSetting(siteID: coupon.siteID, onCompletion: completion)
        stores.dispatch(action)
    }
}

// MARK: - Subtypes
//
private extension CouponDetailsViewModel {
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
