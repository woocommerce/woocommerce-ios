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

        /// iOS 13.1 don't render the tabbar shadow color correcly while in dark mode.
        /// To fix it, we have to specifically set it in the `standardAppearance` object.
        /// Which forces us to set other properties like `badgeBackgroundColor` and `badgeTextAttributes` in the `UITabBarItemAppearance` layouts.
        ///
        if #available(iOS 13.0, *) {
            let standardAppearance = UITabBarAppearance()
            standardAppearance.backgroundColor = .appTabBar
            standardAppearance.shadowColor = .systemColor(.separator)
            applyWooAppearance(to: standardAppearance.inlineLayoutAppearance)
            applyWooAppearance(to: standardAppearance.stackedLayoutAppearance)
            applyWooAppearance(to: standardAppearance.compactInlineLayoutAppearance)
            appearance.standardAppearance = standardAppearance
        }
    }

    @available(iOS 13.0, *)
    private static func applyWooAppearance(to tabBarItemAppearance: UITabBarItemAppearance) {
        tabBarItemAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.textInverted]
        tabBarItemAppearance.selected.badgeTextAttributes = [.foregroundColor: UIColor.textInverted]
        tabBarItemAppearance.disabled.badgeTextAttributes = [.foregroundColor: UIColor.textInverted]
        tabBarItemAppearance.normal.badgeBackgroundColor = .primary
        tabBarItemAppearance.selected.badgeBackgroundColor = .primary
        tabBarItemAppearance.disabled.badgeBackgroundColor = .primary
    }
}
