import UIKit


// MARK: - UISearchBar + Woo
//
extension UISearchBar {

    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance() {
        let appearance = UISearchBar.appearance()
        appearance.barTintColor = .white

        appearance.layer.borderColor = StyleManager.wooGreyBorder.cgColor
        appearance.layer.borderWidth = 1.0

        let brandColor = StyleManager.wooCommerceBrandColor
        appearance.tintColor = brandColor

        let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: brandColor]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(cancelButtonAttributes, for: .normal)

        let textAttributes = [NSAttributedString.Key.foregroundColor: StyleManager.wooGreyMid]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = textAttributes

        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = .red
    }

}
