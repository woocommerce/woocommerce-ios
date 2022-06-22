import Foundation
import Yosemite
import Experiments
import WooFoundation

/// View model for `CouponDetails` view
///
final class CouponDetailsViewModel: ObservableObject {
    let siteID: Int64

    /// Code of the coupon
    ///
    @Published private(set) var couponCode: String = ""

    /// Whether the coupon is still active or has expired
    ///
    @Published private(set) var expiryStatus: String = ""

    /// Text color for the expiry status view
    ///
    @Published private(set) var expiryStatusForegroundColor: UIColor = .clear

    /// Background color for the expiry status view
    ///
    @Published private(set) var expiryStatusBackgroundColor: UIColor = .clear

    /// Description of the coupon
    ///
    @Published private(set) var description: String = ""

    /// Discount type of the coupon
    ///
    @Published private(set) var discountType: String = ""

    /// Amount of the coupon
    ///
    @Published private(set) var amount: String = ""

    /// Total number of times this coupon can be used
    ///
    @Published private(set) var usageLimit: Int64 = Constants.noLimit

    /// Number of times this coupon be used per customer
    ///
    @Published private(set) var usageLimitPerUser: Int64 = Constants.noLimit

    /// Maximum number of items which the coupon can be applied to in the cart
    /// 
    @Published private(set) var limitUsageToXItems: Int64 = Constants.noLimit

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

    /// Whether the coupon can only be used alone (`true`) or in conjunction with other coupons (`false`)
    ///
    @Published private(set) var individualUseOnly: Bool = false

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

    /// Indicates whether a network call is in progress
    ///
    @Published private(set) var isDeletionInProgress: Bool = false

    private(set) lazy var addEditCouponViewModel: AddEditCouponViewModel = createAddEditCouponViewModel(with: coupon)

    /// The message to be shared about the coupon
    ///
    var shareMessage: String {
        coupon.generateShareMessage(currencySettings: currencySettings)
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

    var shouldDisplayLimitUsageToXItems: Bool {
        limitUsageToXItems > 0 && coupon.discountType != .fixedCart
    }

    private let stores: StoresManager
    private let currencySettings: CurrencySettings

    let isEditingEnabled: Bool
    let isDeletingEnabled: Bool

    // Closure to be triggered when the coupon is updated successfully
    let onUpdate: () -> Void

    // Closure to be triggered when the coupon is deleted successfully
    let onDeletion: () -> Void

    init(coupon: Coupon,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         featureFlags: FeatureFlagService = ServiceLocator.featureFlagService,
         onUpdate: @escaping () -> Void = {},
         onDeletion: @escaping () -> Void = {}) {
        self.siteID = coupon.siteID
        self.coupon = coupon
        self.stores = stores
        self.currencySettings = currencySettings
        self.onDeletion = onDeletion
        self.onUpdate = onUpdate

        isEditingEnabled = featureFlags.isFeatureFlagEnabled(.couponEditing) && coupon.discountType != .other
        isDeletingEnabled = featureFlags.isFeatureFlagEnabled(.couponDeletion)
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

    func updateCoupon(_ coupon: Coupon) {
        self.coupon = coupon
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

    func deleteCoupon(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        isDeletionInProgress = true
        let action = CouponAction.deleteCoupon(siteID: siteID, couponID: coupon.couponID) { [weak self] result in
            self?.isDeletionInProgress = false
            switch result {
            case .success:
                ServiceLocator.analytics.track(.couponDeleteSuccess)
                onSuccess()
            case .failure(let error):
                DDLogError("⛔️ Error deleting coupon: \(error)")
                ServiceLocator.analytics.track(.couponDeleteFailed, withError: error)
                onFailure()
            }
        }
        stores.dispatch(action)
    }

    func resetAddEditViewModel() {
        addEditCouponViewModel = createAddEditCouponViewModel(with: coupon)
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

        expiryDate = coupon.dateExpires?.toString(dateStyle: .long, timeStyle: .none, timeZone: TimeZone.siteTimezone) ?? ""
        usageLimit = coupon.usageLimit ?? Constants.noLimit
        usageLimitPerUser = coupon.usageLimitPerUser ?? Constants.noLimit
        limitUsageToXItems = coupon.limitUsageToXItems ?? Constants.noLimit
        excludeSaleItems = coupon.excludeSaleItems

        if let digitMinimumAmount = Double(coupon.minimumAmount), digitMinimumAmount > 0 {
            minimumAmount = formatStringAmount(coupon.minimumAmount)
        }

        if let digitMaximumAmount = Double(coupon.maximumAmount), digitMaximumAmount > 0 {
            maximumAmount = formatStringAmount(coupon.maximumAmount)
        }

        allowsFreeShipping = coupon.freeShipping
        emailRestrictions = coupon.emailRestrictions
        individualUseOnly = coupon.individualUse

        let status = coupon.expiryStatus()
        expiryStatus = status.localizedName
        expiryStatusBackgroundColor = status.statusBackgroundColor
        expiryStatusForegroundColor = status.statusForegroundColor
    }

    func formatStringAmount(_ amount: String) -> String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        return currencyFormatter.formatAmount(amount) ?? ""
    }

    func retrieveAnalyticsSetting(completion: @escaping (Result<Bool, Error>) -> Void) {
        let action = SettingAction.retrieveAnalyticsSetting(siteID: coupon.siteID, onCompletion: completion)
        stores.dispatch(action)
    }

    func createAddEditCouponViewModel(with coupon: Coupon) -> AddEditCouponViewModel {
        .init(existingCoupon: coupon, onSuccess: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let updatedCoupon):
                self.updateCoupon(updatedCoupon)
                self.onUpdate()
            default:
                break
            }
        })
    }
}

// MARK: - Subtypes
//
private extension CouponDetailsViewModel {
    enum Constants {
        static let noLimit: Int64 = -1
    }
}
