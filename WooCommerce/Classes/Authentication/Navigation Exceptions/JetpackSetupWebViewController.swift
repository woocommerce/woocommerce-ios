import Combine
import UIKit
import WebKit

/// The web view to handle Jetpack installation/activation/connection all at once.
///
final class JetpackSetupWebViewController: UIViewController {

    /// The site URL to set up Jetpack for.
    private let siteURL: String
    private let analytics: Analytics

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

    init(siteURL: String, analytics: Analytics = ServiceLocator.analytics, onCompletion: @escaping () -> Void) {
        self.siteURL = siteURL
        self.analytics = analytics
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            analytics.track(event: .loginJetpackSetupDismissed(source: .web))
        }
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
        analytics.track(event: .loginJetpackSetupCompleted(source: .web))
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
        guard let navigationURL = navigationAction.request.url?.absoluteString else {
            return
        }
        switch navigationURL {
        // When the web view is about to navigate to the redirect URL for mobile, we can assume that the setup has completed.
        case Constants.mobileRedirectURL:
            decisionHandler(.cancel)
            handleSetupCompletion()
        default:
            if let match = JetpackSetupWebSteps.matchingStep(for: navigationURL) {
                analytics.track(event: .loginJetpackSetupFlow(source: .web, step: match.trackingStep))
            }
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
        static let mobileRedirectURL = "woocommerce://jetpack-connected"
    }

    enum JetpackSetupWebSteps: CaseIterable {
        case automaticInstall
        case wpcomLogin
        case authorize
        case siteLogin
        case pluginDetail
        case pluginInstallation
        case pluginActivation
        case pluginSetup

        var path: String {
            switch self {
            case .automaticInstall:
                return "https://wordpress.com/jetpack/connect/install"
            case .wpcomLogin:
                return "https://wordpress.com/log-in/jetpack"
            case .authorize:
                return "https://wordpress.com/jetpack/connect/authorize"
            case .siteLogin:
                return "wp-admin/wp-login.php"
            case .pluginDetail:
                return "wp-admin/plugin-install.php"
            case .pluginInstallation:
                return "wp-admin/update.php?action=install-plugin"
            case .pluginActivation:
                return "wp-admin/plugins.php?action=activate"
            case .pluginSetup:
                return "wp-admin/admin.php?page=jetpack"
            }
        }

        var trackingStep: WooAnalyticsEvent.LoginJetpackSetupStep {
            switch self {
            case .automaticInstall: return .automaticInstall
            case .wpcomLogin: return .wpcomLogin
            case .authorize: return .authorize
            case .siteLogin: return .siteLogin
            case .pluginDetail: return .pluginDetail
            case .pluginInstallation: return .pluginInstallation
            case .pluginActivation: return .pluginActivation
            case .pluginSetup: return .pluginSetup
            }
        }

        static func matchingStep(for url: String) -> Self? {
            Self.allCases.first { step in
                url.contains(step.path)
            }
        }
    }

    enum Localization {
        static let title = NSLocalizedString("Jetpack Setup", comment: "Title of the Jetpack Setup screen")
    }
}
