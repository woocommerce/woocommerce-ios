import Foundation
import UIKit


// MARK: - UINavigationBar + Woo
//
extension UINavigationBar {

    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance() {
        let appearance = wooAppearance()
        UINavigationBar.appearance().tintColor = .accent // The color of bar button items in the navigation bar
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    /// Creates the default WC's Appearance
    ///
    class func wooAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .listForeground(modal: false)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.text]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.text]
        return appearance
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

    /// Removes the shadow from the bar by removing it from all appearances
    ///
    func removeShadow() {
        let updatedSandardAppearance = self.standardAppearance
        updatedSandardAppearance.removeShadow()
        self.standardAppearance = updatedSandardAppearance

        let updatedCompactAppearance = self.compactAppearance ?? UINavigationBar.wooAppearance()
        updatedCompactAppearance.removeShadow()
        self.compactAppearance = updatedCompactAppearance

        let updatedScrollEdgeAppearance = self.scrollEdgeAppearance ?? UINavigationBar.wooAppearance()
        updatedScrollEdgeAppearance.removeShadow()
        self.scrollEdgeAppearance = updatedScrollEdgeAppearance
    }
}

extension UINavigationBarAppearance {
    func removeShadow() {
        shadowImage = nil
        shadowColor = .none
    }
}
