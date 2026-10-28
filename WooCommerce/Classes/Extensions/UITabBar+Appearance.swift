import StoreDesignSystem
import SwiftUI
import UIKit


// MARK: - UITabBar + Woo
//
extension UITabBar {
    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance(usesStoreDesignSystem: Bool = ServiceLocator.featureFlagService.usesStoreDesignSystem) {
        let appearance = Self.appearance()
        appearance.tintColor = usesStoreDesignSystem ? UIColor(Color.storeOnSurface) : .accent
        appearance.unselectedItemTintColor = usesStoreDesignSystem ? UIColor(Color.storeOnSurface) : nil

        // tab bar needs to be translucent to get rid of the extra space at the bottom of
        // the view controllers embedded in split view.
        appearance.isTranslucent = true

        let tabBarAppearance = wooAppearance(usesStoreDesignSystem: usesStoreDesignSystem)
        appearance.standardAppearance = tabBarAppearance
        appearance.scrollEdgeAppearance = tabBarAppearance
    }

    /// Creates an appearance object for a tabbar with the default WC style.
    ///
    static func wooAppearance(usesStoreDesignSystem: Bool = ServiceLocator.featureFlagService.usesStoreDesignSystem) -> UITabBarAppearance {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        applyWooAppearance(to: standardAppearance.inlineLayoutAppearance, usesStoreDesignSystem: usesStoreDesignSystem)
        applyWooAppearance(to: standardAppearance.stackedLayoutAppearance, usesStoreDesignSystem: usesStoreDesignSystem)
        applyWooAppearance(to: standardAppearance.compactInlineLayoutAppearance, usesStoreDesignSystem: usesStoreDesignSystem)
        return standardAppearance
    }

    /// Configures the appearance object for a tabbar's items with the default WC style.
    ///
    private static func applyWooAppearance(to tabBarItemAppearance: UITabBarItemAppearance, usesStoreDesignSystem: Bool) {
        let badgeTextColor = usesStoreDesignSystem ? UIColor(Color.storeOnError) : .white
        let badgeBackgroundColor = usesStoreDesignSystem ? UIColor(Color.storeAlertRed) : .primary
        let badgeTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: badgeTextColor]

        if usesStoreDesignSystem {
            let itemColor = UIColor(Color.storeOnSurface)
            let titleTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: itemColor]

            tabBarItemAppearance.normal.iconColor = itemColor
            tabBarItemAppearance.normal.titleTextAttributes = titleTextAttributes
            tabBarItemAppearance.selected.iconColor = itemColor
            tabBarItemAppearance.selected.titleTextAttributes = titleTextAttributes
            tabBarItemAppearance.focused.iconColor = itemColor
            tabBarItemAppearance.focused.titleTextAttributes = titleTextAttributes
        }

        tabBarItemAppearance.normal.badgeTextAttributes = badgeTextAttributes
        tabBarItemAppearance.selected.badgeTextAttributes = badgeTextAttributes
        tabBarItemAppearance.disabled.badgeTextAttributes = badgeTextAttributes
        tabBarItemAppearance.normal.badgeBackgroundColor = badgeBackgroundColor
        tabBarItemAppearance.selected.badgeBackgroundColor = badgeBackgroundColor
        tabBarItemAppearance.disabled.badgeBackgroundColor = badgeBackgroundColor
    }
}
