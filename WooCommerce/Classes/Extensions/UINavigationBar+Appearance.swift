import Foundation
import UIKit


// MARK: - UINavigationBar + Woo
//
extension UINavigationBar {

    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance() {
        let appearance = UINavigationBar.appearance()
        appearance.barTintColor = StyleManager.wooCommerceBrandColor
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.isTranslucent = false
        appearance.tintColor = .white
    }

    /// Applies UIKit's Default Appearance
    ///
    class func applyDefaultAppearance() {
        let appearance = UINavigationBar.appearance()
        appearance.barTintColor = nil
        appearance.titleTextAttributes = nil
        appearance.tintColor = nil
    }
}
