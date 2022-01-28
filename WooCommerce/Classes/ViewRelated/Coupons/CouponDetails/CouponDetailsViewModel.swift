import Foundation
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
    @Published private(set) var applyTo: String = ""

    /// Expiry date of the coupon
    ///
    @Published private(set) var expiryDate: String = ""
    
    /// The current coupon
    ///
    private let coupon: Coupon

    private let stores: StoresManager

    init(coupon: Coupon,
         stores: StoresManager = ServiceLocator.stores) {
        self.coupon = coupon
        self.stores = stores
        populateDetails()
    }
}

// MARK: - Private helpers
//
private extension CouponDetailsViewModel {
    func populateDetails() {
        couponCode = coupon.code
        description = coupon.description
        amount = coupon.amount
        // TODO: match product IDs to names
        applyTo = coupon.productIds.isEmpty ? Localization.allProducts : "Some Products"
        expiryDate = coupon.dateExpires?.toString(dateStyle: .medium, timeStyle: .none) ?? ""
    }
}

// MARK: - Subtypes
//
private extension CouponDetailsViewModel {
    enum Localization {
        static let allProducts = NSLocalizedString("All Products", comment: "The text to be displayed in when the coupon is not limit to any specific product")
    }
}
