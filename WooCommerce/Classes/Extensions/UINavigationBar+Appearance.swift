import Foundation
import UIKit


// MARK: - UINavigationBar + Woo
//
extension UINavigationBar {

    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance() {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .appBar
            appearance.titleTextAttributes = [.foregroundColor: UIColor.text]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.text]

            UINavigationBar.appearance().tintColor = .accent // The color of bar button items in the navigation bar
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            let appearance = UINavigationBar.appearance()
            appearance.barTintColor = .appBar
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.isTranslucent = false
            appearance.tintColor = .white
        }
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
