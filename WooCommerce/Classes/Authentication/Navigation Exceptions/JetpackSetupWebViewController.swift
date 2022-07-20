import Combine
import UIKit
import WebKit

/// The web view to handle Jetpack installation/activation/connection all at once.
///
final class JetpackSetupWebViewController: UIViewController {

    /// The site URL to set up Jetpack for.
    private let siteURL: String

    /// The closure to trigger when Jetpack setup completes.
    private let completionHandler: () -> Void

    /// Main web view
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()

    /// Progress bar for the web view
    private lazy var progressBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    /// Strong reference for the subscription to update progress bar
    private var progressSubscription: AnyCancellable?

    init(siteURL: String, onCompletion: @escaping () -> Void) {
        self.siteURL = siteURL
        self.completionHandler = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureWebView()
        configureProgressBar()
        startLoading()
    }
}

private extension JetpackSetupWebViewController {
    func configureNavigationBar() {
        title = Localization.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
    }

    func configureWebView() {
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            view.safeTopAnchor.constraint(equalTo: webView.topAnchor),
            view.safeBottomAnchor.constraint(equalTo: webView.bottomAnchor),
        ])
    }

    func configureProgressBar() {
        view.addSubview(progressBar)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: progressBar.trailingAnchor),
            view.safeTopAnchor.constraint(equalTo: progressBar.topAnchor)
        ])
    }

    func startLoading() {
        guard let escapedSiteURL = siteURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: String(format: Constants.jetpackInstallString, escapedSiteURL, Constants.mobileRedirectURL)) else {
            return
        }
        progressSubscription = webView.publisher(for: \.estimatedProgress)
            .sink { [weak self] progress in
                if progress == 1 {
                    self?.progressBar.setProgress(0, animated: false)
                } else {
                    self?.progressBar.setProgress(Float(progress), animated: true)
                }
            }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    @objc func dismissView() {
        // TODO: analytics
        dismiss(animated: true)
    }
}

extension JetpackSetupWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let navigationURL = navigationAction.request.url?.absoluteString
        switch navigationURL {
        // There are 2 cases: user can be redirected to the defined mobile_redirect URL or wp-admin home page.
        // In these cases, we assume that the Jetpack setup has completed.
        case let .some(url) where url == Constants.mobileRedirectURL || url.hasSuffix(Constants.wpadminPath):
            decisionHandler(.cancel)
            completionHandler()
        default:
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressBar.setProgress(0, animated: false)
    }
}

private extension JetpackSetupWebViewController {
    enum Constants {
        static let jetpackInstallString = "https://wordpress.com/jetpack/connect?url=%@&mobile_redirect=%@&from=mobile"
        // TODO: update this URL with woocommerce:// when https://github.com/Automattic/wp-calypso/pull/65715 is merged.
        static let mobileRedirectURL = "wordpress://jetpack-connection"
        static let wpadminPath = "/wp-admin/"
    }

    enum Localization {
        static let title = NSLocalizedString("Jetpack Setup", comment: "Title of the Jetpack Setup screen")
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the Jetpack Setup screen")
    }
}
