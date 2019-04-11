import UIKit


// MARK: - UISearchBar + Woo
//
extension UISearchBar {

    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance() {
        let appearance = UISearchBar.appearance()
        appearance.barTintColor = .white
        appearance.backgroundColor = .red

        let brandColor = StyleManager.wooCommerceBrandColor
        appearance.tintColor = brandColor

        let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: brandColor]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(cancelButtonAttributes, for: .normal)
    }

}
