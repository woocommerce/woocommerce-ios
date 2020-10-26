import Foundation
import UIKit


// MARK: - UINavigationBar + Woo
//
extension UINavigationBar {

    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance() {
        let appearance = UINavigationBar.appearance()
        appearance.barTintColor = .basicBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.text]
        appearance.isTranslucent = false
        appearance.tintColor = .accent
    }

    /// Applies UIKit's Default Appearance
    ///
    class func applyDefaultAppearance() {
        let appearance = UINavigationBar.appearance()
        appearance.barTintColor = nil
        appearance.titleTextAttributes = nil
        appearance.isTranslucent = true
        appearance.tintColor = nil
    }
}
