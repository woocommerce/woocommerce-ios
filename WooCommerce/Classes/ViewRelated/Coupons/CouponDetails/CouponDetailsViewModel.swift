import Combine
import Yosemite
import Foundation

/// View model for `CouponDetails` view
///
final class CouponDetailsViewModel: ObservableObject {
    /// Code of the coupon
    ///
    @Published private(set) var couponCode: String = ""

    /// Description of the coupon
    ///
    @Published private(set) var description: String = ""

    /// Amount of the coupon
    ///
    @Published private(set) var amount: String = ""

    /// Product limit for the coupon to be applied to
    ///
    @Published private(set) var productsAppliedTo: String = ""

    /// Expiry date of the coupon
    ///
    @Published private(set) var expiryDate: String = ""

    /// The current coupon
    ///
    @Published private var coupon: Coupon

    private let stores: StoresManager
    private let currencySettings: CurrencySettings
    private var couponSubscription: AnyCancellable?

    init(coupon: Coupon,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.coupon = coupon
        self.stores = stores
        self.currencySettings = currencySettings
        observeCoupon()
        syncCoupon()
    }
}

// MARK: - Private helpers
//
private extension CouponDetailsViewModel {
    func observeCoupon() {
        couponSubscription =  $coupon
            .sink { [weak self] _ in
                self?.populateDetails()
            }
    }

    func populateDetails() {
        couponCode = coupon.code
        description = coupon.description

        switch coupon.discountType {
        case .percent:
            let percentFormatter = NumberFormatter()
            percentFormatter.numberStyle = .percent
            if let amountDouble = Double(coupon.amount) {
                let amountNumber = NSNumber(value: amountDouble / 100)
                amount = percentFormatter.string(from: amountNumber) ?? ""
            }
        case .fixedCart, .fixedProduct:
            let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
            amount = currencyFormatter.formatAmount(coupon.amount) ?? ""
        case .other: // TODO: confirm this case
            amount = coupon.amount
        }

        // TODO: match product IDs to names
        productsAppliedTo = coupon.productIds.isEmpty ? Localization.allProducts : "Some Products"
        expiryDate = coupon.dateExpires?.toString(dateStyle: .long, timeStyle: .none) ?? ""
    }

    func syncCoupon() {
        let action = CouponAction.retrieveCoupon(siteID: coupon.siteID, couponID: coupon.couponID) { result in
            switch result {
            case .success(let coupon):
                self.coupon = coupon
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing coupon detail: \(error)")
            }
        }
        stores.dispatch(action)
    }
}

// MARK: - Subtypes
//
private extension CouponDetailsViewModel {
    enum Localization {
        static let allProducts = NSLocalizedString("All Products", comment: "The text to be displayed in when the coupon is not limit to any specific product")
        static let singleProduct = NSLocalizedString(
            "%1$d Product",
            comment: "The number of products allowed for a coupon in singular form. Reads like: 1 Product"
        )
        static let multipleProducts = NSLocalizedString(
            "%1$d Products",
            comment: "The number of products allowed for a coupon in plural form. " +
            "Reads like: 10 Products"
        )
        static let singleCategory = NSLocalizedString(
            "%1$d Category",
            comment: "The number of category allowed for a coupon in singular form. Reads like: 1 Category"
        )
        static let pluralNumberOfCategories = NSLocalizedString(
            "%1$d Categories",
            comment: "The number of category allowed for a coupon in plural form. " +
            "Reads like: 10 Categories"
        )
        static let allWithException = NSLocalizedString("All except %1$@", comment: "Exception rule for a coupon. Reads like: All except 2 Products")
        static let ruleWithException = NSLocalizedString("%1$@ except %2$@", comment: "Exception rule for a coupon. Reads like: 3 Products except 1 Category")
        static let combinedRule = NSLocalizedString("%1$@ and %2$@", comment: "Combined rule for a coupon. Reads like: 2 Products and 1 Category")
    }
}
