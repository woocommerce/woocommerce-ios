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
    static func wooAppearance(usesStoreDesignSystem: Bool = ServiceLocator.featureFlagService.usesStoreDesignSystem,
                              colorsItemTitles: Bool = colorsItemTitlesByDefault) -> UITabBarAppearance {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        applyWooAppearance(to: standardAppearance.inlineLayoutAppearance, usesStoreDesignSystem: usesStoreDesignSystem, colorsItemTitles: colorsItemTitles)
        applyWooAppearance(to: standardAppearance.stackedLayoutAppearance, usesStoreDesignSystem: usesStoreDesignSystem, colorsItemTitles: colorsItemTitles)
        applyWooAppearance(to: standardAppearance.compactInlineLayoutAppearance, usesStoreDesignSystem: usesStoreDesignSystem, colorsItemTitles: colorsItemTitles)
        return standardAppearance
    }

    /// On iPad before iOS 26, the tab titles are measured with the stacked layout font before the tab bar is shown,
    /// and UIKit does not measure them again for the wider inline layout when title text attributes are set.
    /// Long titles are then truncated (e.g. "Prod..."), so the titles keep the system colors there.
    private static var colorsItemTitlesByDefault: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return UIDevice.current.userInterfaceIdiom != .pad
    }

    /// Configures the appearance object for a tabbar's items with the default WC style.
    ///
    private static func applyWooAppearance(to tabBarItemAppearance: UITabBarItemAppearance, usesStoreDesignSystem: Bool, colorsItemTitles: Bool) {
        let badgeTextColor = usesStoreDesignSystem ? UIColor(Color.storeOnError) : .white
        let badgeBackgroundColor = usesStoreDesignSystem ? UIColor(Color.storeAccentRed) : .primary
        let badgeTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: badgeTextColor]

        if usesStoreDesignSystem {
            let itemColor = UIColor(Color.storeOnSurface)
            let titleTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: itemColor]

            tabBarItemAppearance.normal.iconColor = itemColor
            tabBarItemAppearance.selected.iconColor = itemColor
            tabBarItemAppearance.focused.iconColor = itemColor
            if colorsItemTitles {
                tabBarItemAppearance.normal.titleTextAttributes = titleTextAttributes
                tabBarItemAppearance.selected.titleTextAttributes = titleTextAttributes
                tabBarItemAppearance.focused.titleTextAttributes = titleTextAttributes
            }
        }

        tabBarItemAppearance.normal.badgeTextAttributes = badgeTextAttributes
        tabBarItemAppearance.selected.badgeTextAttributes = badgeTextAttributes
        tabBarItemAppearance.disabled.badgeTextAttributes = badgeTextAttributes
        tabBarItemAppearance.normal.badgeBackgroundColor = badgeBackgroundColor
        tabBarItemAppearance.selected.badgeBackgroundColor = badgeBackgroundColor
        tabBarItemAppearance.disabled.badgeBackgroundColor = badgeBackgroundColor
    }
}
