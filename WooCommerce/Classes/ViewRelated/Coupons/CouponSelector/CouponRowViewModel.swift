import Foundation
import Yosemite
import WooFoundation

/// View model for `CouponRow`
///
final class CouponRowViewModel: ObservableObject, Identifiable {
    private let currencyFormatter: CurrencyFormatter

    /// Unique ID for the view model.
    ///
    let id: Int64

    // MARK: Coupon properties

    /// Code of the coupon
    ///
    let couponCode: String

    /// Summary of the coupon
    ///
    let summary: String

    /// Selected coupon
    ///
    @Published var isSelected = false

    /// Custom accessibility label for coupon
    ///
    var couponAccessibilityLabel: String {
        [couponCode, summary]
            .compactMap({ $0 })
            .joined(separator: ". ")
    }

    init(id: Int64? = nil,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         couponCode: String,
         summary: String) {
        self.id = id ?? Int64(UUID().uuidString.hashValue)
        self.currencyFormatter = currencyFormatter
        self.couponCode = couponCode
        self.summary = summary
    }
}
