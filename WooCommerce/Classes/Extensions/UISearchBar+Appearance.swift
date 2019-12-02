import UIKit


// MARK: - UISearchBar + Woo
//
extension UISearchBar {

    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance() {
        let appearance = UISearchBar.appearance()
        appearance.barTintColor = .basicBackground

        appearance.layer.borderColor = UIColor.listSmallIcon.cgColor
        appearance.layer.borderWidth = 1.0

        let brandColor = UIColor.primary
        appearance.tintColor = brandColor

        let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: brandColor]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(cancelButtonAttributes, for: .normal)

        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.textTertiary]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = textAttributes
    }
}


// Setting the UITextField background color via the appearance proxy does not seem to work
// As a workaround, this property exposes the texfield, so the background color can be set manually
//
extension UISearchBar {
    var textField: UITextField? {
        return subviews.map { $0.subviews.first(where: { $0 is UITextInputTraits}) as? UITextField }
            .compactMap { $0 }
            .first
    }
}
