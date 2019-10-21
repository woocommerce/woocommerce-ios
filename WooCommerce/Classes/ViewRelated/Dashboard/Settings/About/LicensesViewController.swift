import SafariServices
import UIKit
import WebKit

class LicensesViewController: UIViewController {

    /// Main WebView
    ///
    @IBOutlet weak private var webView: WKWebView!

    /// URL to the local licenses HTML file
    ///
    private lazy var licenseURL: URL = {
        return Bundle.main.url(forResource: "licenses", withExtension: "html")!
    }()

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureWebView()
    }
}


// MARK: - View Configuration
//
extension LicensesViewController {

    /// Set the title and back button.
    ///
    fileprivate func configureNavigation() {
        title = NSLocalizedString("Licenses", comment: "Licenses (information page title)")
        // Don't show the About title in the next-view's back button
        let backButton = UIBarButtonItem(
            title: String(),
            style: .plain,
            target: nil,
            action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    /// Setup the main view
    ///
    fileprivate func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Setup the web view
    ///
    fileprivate func configureWebView() {
        webView.navigationDelegate = self
        webView.loadFileURL(licenseURL, allowingReadAccessTo: licenseURL)
    }
}


// MARK: - WKNavigationDelegate Conformance
//
extension LicensesViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        guard navigationAction.navigationType == .linkActivated else {
            decisionHandler(.allow)
            return
        }

        // Open the link in a modal SFSafariViewController instead of the webview displaying the
        // licenses HTML — we don't want to build another browser here
        if let url = navigationAction.request.url {
            let safariViewController = SFSafariViewController(url: url)
            safariViewController.modalPresentationStyle = .pageSheet
            present(safariViewController, animated: true, completion: nil)
        }
        decisionHandler(.cancel)
    }
}
