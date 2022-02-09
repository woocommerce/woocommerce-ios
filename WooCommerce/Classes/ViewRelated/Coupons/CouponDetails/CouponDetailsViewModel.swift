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
    @Published private(set) var productsAppliedTo: String = ""

    /// Expiry date of the coupon
    ///
    @Published private(set) var expiryDate: String = ""

    var shareMessage: String {
        if coupon.productIds.isNotEmpty ||
            coupon.productCategories.isNotEmpty ||
            coupon.excludedProductIds.isNotEmpty ||
            coupon.excludedProductCategories.isNotEmpty {
            return String.localizedStringWithFormat(Localization.shareMessageSomeProducts, amount, couponCode)
        }
        return String.localizedStringWithFormat(Localization.shareMessageAllProducts, amount, couponCode)
    }

    /// The current coupon
    ///
    private let coupon: Coupon

    private let stores: StoresManager
    private let currencySettings: CurrencySettings

    init(coupon: Coupon,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.coupon = coupon
        self.stores = stores
        self.currencySettings = currencySettings
        populateDetails()
    }
}

// MARK: - Private helpers
//
private extension CouponDetailsViewModel {
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
        static let allProducts = NSLocalizedString("All Products", comment: "The text to be displayed in when the coupon is not limit to any specific product")
    }
}
