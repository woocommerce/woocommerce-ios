import UIKit

class FreeTrialFeatures {
    /// Free Trial feature representation
    ///
    struct Feature {
        let title: String
        let icon: UIImage
    }

    /// Free Trial Features
    ///
    static let features: [Feature] = [
        .init(title: Localization.Feature.premiumThemes, icon: .premiumThemesIcon),
        .init(title: Localization.Feature.unlimitedProducts, icon: .unlimitedProductsIcon),
        .init(title: Localization.Feature.shippingLabels, icon: .shippingOutlineIcon),
        .init(title: Localization.Feature.ecommerceReports, icon: .ecommerceIcon),
        .init(title: Localization.Feature.paymentOptions, icon: .paymentOptionsIcon),
        .init(title: Localization.Feature.subscriptions, icon: .giftIcon),
        .init(title: Localization.Feature.advertising, icon: .advertisingIcon),
        .init(title: Localization.Feature.marketing, icon: .emailOutlineIcon),
        .init(title: Localization.Feature.support, icon: .supportIcon),
        .init(title: Localization.Feature.backups, icon: .backupsIcon),
        .init(title: Localization.Feature.security, icon: .siteSecurityIcon),
        .init(title: Localization.Feature.launch, icon: .launchIcon)
    ]
}

private extension FreeTrialFeatures {
    enum Localization {
        enum Feature {
            static let premiumThemes = NSLocalizedString("Premium themes", comment: "Premium Themes title feature on the Free Trial Summary Screen")
            static let unlimitedProducts = NSLocalizedString("Unlimited products", comment: "Unlimited products title feature on the Free Trial Summary Screen")
            static let shippingLabels = NSLocalizedString("Shipping labels", comment: "Shipping labels title feature on the Free Trial Summary Screen")
            static let ecommerceReports = NSLocalizedString("Ecommerce reports", comment: "Ecommerce reports title feature on the Free Trial Summary Screen")
            static let paymentOptions = NSLocalizedString("Multiple payment options",
                    comment: "Multiple payment options title feature on the Free Trial Summary Screen")
            static let subscriptions = NSLocalizedString("Subscriptions & product kits",
                    comment: "Subscriptions & product kits title feature on the Free Trial Summary Screen")
            static let advertising = NSLocalizedString("Social advertising", comment: "Social advertising title feature on the Free Trial Summary Screen")
            static let marketing = NSLocalizedString("Email marketing", comment: "Email marketing title feature on the Free Trial Summary Screen")
            static let support = NSLocalizedString("24/7 support", comment: "24/7 support title feature on the Free Trial Summary Screen")
            static let backups = NSLocalizedString("Auto updates & backups", comment: "Auto updates & backups title feature on the Free Trial Summary Screen")
            static let security = NSLocalizedString("Site security", comment: "Site security title feature on the Free Trial Summary Screen")
            static let launch = NSLocalizedString("Fast to launch", comment: "Fast to launch title feature on the Free Trial Summary Screen")
        }
    }
}
