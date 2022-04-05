import UIKit


// MARK: - UITabBar + Woo
//
extension UITabBar {
    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance() {
        let appearance = Self.appearance()
        appearance.barTintColor = .appTabBar
        appearance.tintColor = .text
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) {
            // tab bar needs to be translucent to get rid of the extra space at the bottom of
            // the view controllers embedded in split view.
            appearance.isTranslucent = true
        }

        /// iOS 13.0 and 13.1 doesn't render the tabbar shadow color correctly while in dark mode.
        /// To fix it, we have to specifically set it in the `standardAppearance` object.
        ///
        appearance.standardAppearance = createWooTabBarAppearance()

        /// This is needed because the tab bar background has the wrong color under iOS 15 (using Xcode 13).
        /// More: issue-5018
        ///
        if #available(iOS 15.0, *) {
            appearance.scrollEdgeAppearance = appearance.standardAppearance
        }
    }

    /// Creates an appearance object for a tabbar with the default WC style.
    ///
    private static func createWooTabBarAppearance() -> UITabBarAppearance {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.backgroundColor = .appTabBar
        standardAppearance.shadowColor = .systemColor(.separator)
        applyWooAppearance(to: standardAppearance.inlineLayoutAppearance)
        applyWooAppearance(to: standardAppearance.stackedLayoutAppearance)
        applyWooAppearance(to: standardAppearance.compactInlineLayoutAppearance)
        return standardAppearance
    }

    /// Configures the appearance object for a tabbar's items with the default WC style.
    ///
    private static func applyWooAppearance(to tabBarItemAppearance: UITabBarItemAppearance) {
        tabBarItemAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.textInverted]
        tabBarItemAppearance.selected.badgeTextAttributes = [.foregroundColor: UIColor.textInverted]
        tabBarItemAppearance.disabled.badgeTextAttributes = [.foregroundColor: UIColor.textInverted]
        tabBarItemAppearance.normal.badgeBackgroundColor = .primary
        tabBarItemAppearance.selected.badgeBackgroundColor = .primary
        tabBarItemAppearance.disabled.badgeBackgroundColor = .primary
    }
}
