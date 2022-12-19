import UIKit

/// View model for `StoreCreationPlanView`.
struct StoreCreationPlanViewModel {
    /// Describes a feature for the WPCOM plan with an icon.
    struct Feature {
        let icon: UIImage
        let title: String
    }

    /// The WPCOM plan to purchase.
    let plan: WPComPlanProduct

    /// A list of features included in the WPCOM plan.
    let features: [Feature] = [
        .init(icon: .gridicon(.starOutline), title: Localization.themeFeature),
        .init(icon: .gridicon(.product), title: Localization.productsFeature),
        .init(icon: .gridicon(.gift), title: Localization.subscriptionsFeature),
        .init(icon: .gridicon(.statsAlt), title: Localization.reportFeature),
        .init(icon: .currencyImage, title: Localization.paymentOptionsFeature),
        .init(icon: .gridicon(.shipping), title: Localization.shippingLabelsFeature),
        .init(icon: .megaphoneIcon, title: Localization.salesChannelsFeature),
    ]
}

private extension StoreCreationPlanViewModel {
    enum Localization {
        static let themeFeature = NSLocalizedString(
            "Premium themes",
            comment: "Title of eCommerce plan feature on the store creation plan screen."
        )
        static let productsFeature = NSLocalizedString(
            "Unlimited products",
            comment: "Title of eCommerce plan feature on the store creation plan screen."
        )
        static let subscriptionsFeature = NSLocalizedString(
            "Subscriptions & giftcards",
            comment: "Title of eCommerce plan feature on the store creation plan screen."
        )
        static let reportFeature = NSLocalizedString(
            "Ecommerce reports",
            comment: "Title of eCommerce plan feature on the store creation plan screen."
        )
        static let paymentOptionsFeature = NSLocalizedString(
            "Multiple payment options",
            comment: "Title of eCommerce plan feature on the store creation plan screen."
        )
        static let shippingLabelsFeature = NSLocalizedString(
            "Shipping labels",
            comment: "Title of eCommerce plan feature on the store creation plan screen."
        )
        static let salesChannelsFeature = NSLocalizedString(
            "Sales channels",
            comment: "Title of eCommerce plan feature on the store creation plan screen."
        )
    }
}
