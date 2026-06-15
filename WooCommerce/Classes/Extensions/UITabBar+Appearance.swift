import UIKit


// MARK: - UITabBar + Woo
//
extension UITabBar {
    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance() {
        let appearance = Self.appearance()
        appearance.tintColor = .accent

        // tab bar needs to be translucent to get rid of the extra space at the bottom of
        // the view controllers embedded in split view.
        appearance.isTranslucent = true

        appearance.barTintColor = nil

        let tabBarAppearance = wooAppearance()
        appearance.standardAppearance = tabBarAppearance
        appearance.scrollEdgeAppearance = tabBarAppearance
    }

    /// Creates an appearance object for a tabbar with the default WC style.
    ///
    static func wooAppearance() -> UITabBarAppearance {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        applyWooAppearance(to: standardAppearance.inlineLayoutAppearance)
        applyWooAppearance(to: standardAppearance.stackedLayoutAppearance)
        applyWooAppearance(to: standardAppearance.compactInlineLayoutAppearance)
        return standardAppearance
    }

    /// Configures the appearance object for a tabbar's items with the default WC style.
    ///
    private static func applyWooAppearance(to tabBarItemAppearance: UITabBarItemAppearance) {
        tabBarItemAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.white]
        tabBarItemAppearance.selected.badgeTextAttributes = [.foregroundColor: UIColor.white]
        tabBarItemAppearance.disabled.badgeTextAttributes = [.foregroundColor: UIColor.white]
        tabBarItemAppearance.normal.badgeBackgroundColor = .primary
        tabBarItemAppearance.selected.badgeBackgroundColor = .primary
        tabBarItemAppearance.disabled.badgeBackgroundColor = .primary
    }
}
