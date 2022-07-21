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

    /// Activity indicator for fetching sites after setup completes
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
    }

    func configureWebView() {
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            view.safeTopAnchor.constraint(equalTo: webView.topAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
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

    func handleSetupCompletion() {
        activityIndicator.startAnimating()
        // tries re-syncing to get an updated store list
        // then attempts to present epilogue again
        ServiceLocator.stores.synchronizeEntities { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.completionHandler()
        }
    }
}

extension JetpackSetupWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let navigationURL = navigationAction.request.url?.absoluteString
        switch navigationURL {
        // When the web view is about to navigate to the redirect URL for mobile, we can assume that the setup has completed.
        case let .some(url) where url == Constants.mobileRedirectURL:
            decisionHandler(.cancel)
            handleSetupCompletion()
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
    }

    enum Localization {
        static let title = NSLocalizedString("Jetpack Setup", comment: "Title of the Jetpack Setup screen")
    }
}
