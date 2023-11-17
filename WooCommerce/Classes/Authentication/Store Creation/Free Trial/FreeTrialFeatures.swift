import UIKit

/// Defines all Free Trial Features that may be displayed in any UI section of the app
///
struct FreeTrialFeatures {
    /// Free Trial feature representation
    ///
    struct Feature {
        let title: String
        let contents: [String]
    }

    /// Free Trial Features
    ///
    static let features: [Feature] = [
        .init(title: Localization.Title.startSellingQuickly, contents: [
            Localization.Feature.themes,
            Localization.Feature.storeManagement,
            Localization.Feature.codeFree
        ]),
        .init(title: Localization.Title.growYourBusiness, contents: [
            Localization.Feature.seo,
            Localization.Feature.advertising,
            Localization.Feature.email
        ]),
        .init(title: Localization.Title.hassleFreeStoreOwnership, contents: [
            Localization.Feature.hosting,
            Localization.Feature.backups,
            Localization.Feature.support
        ])
    ]
}

private extension FreeTrialFeatures {
    enum Localization {
        enum Title {
            static let startSellingQuickly = NSLocalizedString("Start selling quickly", comment: "Title of features on the Free Trial Summary screen")
            static let growYourBusiness = NSLocalizedString("Grow your business", comment: "Title of features on the Free Trial Summary screen")
            static let hassleFreeStoreOwnership = NSLocalizedString(
                "Hassle-free store ownership",
                comment: "Title of features on the Free Trial Summary screen"
            )
        }
        enum Feature {
            static let themes = NSLocalizedString("Premium themes", comment: "Premium Themes title feature on the Free Trial Summary Screen")
            static let storeManagement = NSLocalizedString("Store management tools", comment: "Store management title feature on the Free Trial Summary Screen")
            static let codeFree = NSLocalizedString("Code-free design and editing", comment: "Code-free title feature on the Free Trial Summary Screen")
            static let seo = NSLocalizedString("Built-in SEO", comment: "SEO title feature on the Free Trial Summary Screen")
            static let advertising = NSLocalizedString("Social advertising", comment: "Social advertising title feature on the Free Trial Summary Screen")
            static let email = NSLocalizedString("Automated customer emails", comment: "Email title feature on the Free Trial Summary Screen")
            static let hosting = NSLocalizedString("Best-in-class hosting", comment: "Hosting title feature on the Free Trial Summary Screen")
            static let backups = NSLocalizedString("Automated site backups", comment: "Site backup title feature on the Free Trial Summary Screen")
            static let support = NSLocalizedString("24/7 priority support", comment: "24/7 support title feature on the Free Trial Summary Screen")
        }
    }
}
