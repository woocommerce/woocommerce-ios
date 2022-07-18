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
        bar.tintColor = .brand
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
    }
}

private extension JetpackSetupWebViewController {
    func configureNavigationBar() {
        title = Localization.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
    }

    func configureWebView() {
        view.addSubview(webView)
        view.pinSubviewToSafeArea(webView)

        guard let escapedSiteURL = siteURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: String(format: Constants.jetpackInstallString, escapedSiteURL, Constants.mobileRedirectURL)) else {
            return
        }

        let request = URLRequest(url: url)
        webView.load(request)
        progressSubscription = webView.publisher(for: \.estimatedProgress)
            .sink { [weak self] progress in
                self?.progressBar.isHidden = progress == 1 // hides the progress bar when done loading
                self?.progressBar.setProgress(Float(progress), animated: false)
            }
    }

    func configureProgressBar() {
        view.addSubview(progressBar)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: progressBar.trailingAnchor),
            view.topAnchor.constraint(equalTo: progressBar.topAnchor)
        ])
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
        case let .some(url) where url == Constants.mobileRedirectURL:
            decisionHandler(.cancel)
            completionHandler()
        default:
            decisionHandler(.allow)
        }
    }
}

private extension JetpackSetupWebViewController {
    enum Constants {
        static let jetpackInstallString = "https://wordpress.com/jetpack/connect?url=%@&mobile_redirect=%@&from=mobile"
        static let mobileRedirectURL = "wordpress://jetpack-connection"
    }

    enum Localization {
        static let title = NSLocalizedString("Setup Jetpack", comment: "Title of the Setup Jetpack screen")
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the Setup Jetpack screen")
    }
}
