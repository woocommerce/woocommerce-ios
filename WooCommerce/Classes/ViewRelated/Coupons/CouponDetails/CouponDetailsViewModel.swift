import Combine
import Yosemite

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
    }
}
