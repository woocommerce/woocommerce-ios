import Foundation
import Yosemite

/// A reason a product cannot be added to an order.
///
/// Owns the check and the wording that goes with it, so every route onto an order answers the question the
/// same way.
///
enum ProductRestriction: CaseIterable {
    case subscription
    case bookable

    /// The restriction preventing the product from being added to an order, or `nil` if there is none.
    /// The first matching case wins.
    ///
    static func restriction(for product: Product) -> ProductRestriction? {
        allCases.first { $0.applies(to: product) }
    }

    func applies(to product: Product) -> Bool {
        switch self {
        case .subscription: product.productType.isSubscription
        case .bookable: product.productType.isBookable
        }
    }

    /// Shown under the product name in the selector, and in the notice when a scanned product is refused.
    var reason: String {
        switch self {
        case .subscription: Localization.subscriptionReason
        case .bookable: Localization.bookableReason
        }
    }

    /// Shown when the restricted product is inside a bundle, where the bundle itself isn't the problem.
    var bundleReason: String {
        switch self {
        case .subscription: Localization.subscriptionBundleReason
        case .bookable: Localization.bookableBundleReason
        }
    }
}

private extension ProductRestriction {
    enum Localization {
        static let subscriptionReason = NSLocalizedString(
            "productSelectorViewModel.subscriptionProductUnsupportedReason",
            value: "Subscription products are not supported for order creation",
            comment: "Message explaining unsupported subscription products for order creation")
        static let bookableReason = NSLocalizedString(
            "productSelectorViewModel.bookableProductUnsupportedReason",
            value: "Bookable products are not supported for order creation",
            comment: "Message explaining unsupported bookable products for order creation")
        static let subscriptionBundleReason = NSLocalizedString(
            "orderCreationProductRestrictions.subscriptionBundleReason",
            value: "Bundles with subscription products are not supported",
            comment: "Message shown when a merchant tries to add a bundle holding a subscription product to an order.")
        static let bookableBundleReason = NSLocalizedString(
            "orderCreationProductRestrictions.bookableBundleReason",
            value: "Bundles with bookable products are not supported",
            comment: "Message shown when a merchant tries to add a bundle holding a bookable product to an order.")
    }
}
