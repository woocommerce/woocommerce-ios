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

        /// Some iOS 13.x versions don't render the tabbar shadow color correcly while in dark mode.
        /// To fix it, we have to specifically set it in the `standardAppearance` object.
        /// Which forces us to set other properties like `badgeBackgroundColor` and `badgeTextAttributes` in the `UITabBarItemAppearance` layouts.
        ///
        if #available(iOS 13.0, *) {
            let standardAppearance = UITabBarAppearance()
            standardAppearance.backgroundColor = .appTabBar
            standardAppearance.shadowColor = .systemColor(.separator)
            applyItemWooAppearance(to: standardAppearance.inlineLayoutAppearance)
            applyItemWooAppearance(to: standardAppearance.stackedLayoutAppearance)
            applyItemWooAppearance(to: standardAppearance.compactInlineLayoutAppearance)
            appearance.standardAppearance = standardAppearance
        }
    }

    @available(iOS 13.0, *)
    private class func applyItemWooAppearance(to layoutAppearance: UITabBarItemAppearance) {
        layoutAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.textInverted]
        layoutAppearance.selected.badgeTextAttributes = [.foregroundColor: UIColor.textInverted]
        layoutAppearance.disabled.badgeTextAttributes = [.foregroundColor: UIColor.textInverted]
        layoutAppearance.normal.badgeBackgroundColor = .primary
        layoutAppearance.selected.badgeBackgroundColor = .primary
        layoutAppearance.disabled.badgeBackgroundColor = .primary
    }
}
