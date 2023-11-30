import UIKit
import Foundation

extension UINavigationItem {
    /// Assigns a loading indicator to the `leftBarButtonItem`
    /// This is useful when the action that follows a tap on the button is still performing, thus blocking another tap.
    ///
    func configureLeftBarButtonItemAsLoader() {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .navigationBarLoadingIndicator
        indicator.startAnimating()
        leftBarButtonItem = UIBarButtonItem(customView: indicator)
    }
}
