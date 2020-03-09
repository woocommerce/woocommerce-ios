import Foundation
import UIKit
import SafariServices

final class WebviewHelper {

    /// Launch webview URLs using a common style.
    ///
    /// - Parameters:
    ///   - stringURL: the unconverted URL string
    ///   - sender: the view controller that will present the webview
    ///
    static func launch(_ stringURL: String?, with sender: UIViewController) {
        guard let urlString = stringURL,
            let url = URL(string: urlString) else {
                DDLogError("Webview Helper Error - could not convert string to URL: \(String(describing: stringURL)).")
                return
        }

        launch(url, with: sender)
    }

    /// Launch webview URLs using a common style.
    ///
    /// - Parameters:
    ///   - URL: the URL
    ///   - sender: the view controller that will present the webview
    ///
    static func launch(_ url: URL, with sender: UIViewController) {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        sender.present(safariViewController, animated: true, completion: nil)
    }
}
