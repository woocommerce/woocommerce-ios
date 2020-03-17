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

        /// iOS 13.0 and 13.1 doesn't render the tabbar shadow color correcly while in dark mode.
        /// To fix it, we have to specifically set it in the `standardAppearance` object.
        ///
        if #available(iOS 13.0, *) {
            appearance.standardAppearance = createWooTabBarAppearance()
        }
    }

    /// Creates an iOS 13+ appearance object for a tabbar with the default WC style.
    ///
    @available(iOS 13.0, *)
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
