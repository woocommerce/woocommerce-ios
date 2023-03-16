import Combine
import UIKit
import WebKit
import class Networking.UserAgent
import struct WordPressAuthenticator.WordPressOrgCredentials
import enum Yosemite.Credentials

/// A web view which is authenticated for WordPress.com, when possible.
///
final class AuthenticatedWebViewController: UIViewController {

    private let viewModel: AuthenticatedWebViewModel

    /// Main web view
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.customUserAgent = UserAgent.defaultUserAgent
        webView.navigationDelegate = self
        webView.uiDelegate = self
        return webView
    }()

    /// Progress bar for the web view
    private lazy var progressBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    /// Strong reference for the subscription to update progress bar
    private var subscriptions: Set<AnyCancellable> = []

    /// Optional credentials for authenticating with WP.org
    ///
    private let siteCredentials: WordPressOrgCredentials?

    private let wpcomCredentials: Credentials?


    init(viewModel: AuthenticatedWebViewModel, extraCredentials: Credentials? = nil) {
        self.viewModel = viewModel
        let currentCredentials = ServiceLocator.stores.sessionManager.defaultCredentials

        self.siteCredentials = {
            if case let.wporg(username, password, siteAddress) = extraCredentials {
                return WordPressOrgCredentials(username: username,
                                               password: password,
                                               xmlrpc: siteAddress + "/xmlrpc.php",
                                               options: [:])
            } else if case let.wporg(username, password, siteAddress) = currentCredentials {
                return WordPressOrgCredentials(username: username,
                                               password: password,
                                               xmlrpc: siteAddress + "/xmlrpc.php",
                                               options: [:])
            }
            return nil
        }()

        self.wpcomCredentials = {
            if case .wpcom = extraCredentials {
                return extraCredentials
            } else if case .wpcom = currentCredentials {
                return currentCredentials
            }
            return nil
        }()
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
        if isBeingDismissedInAnyWay {
            viewModel.handleDismissal()
        }
    }
}

private extension AuthenticatedWebViewController {
    func configureNavigationBar() {
        title = viewModel.title
    }

    func configureWebView() {
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            view.safeTopAnchor.constraint(equalTo: webView.topAnchor),
            view.safeBottomAnchor.constraint(equalTo: webView.bottomAnchor),
        ])

        extendContentUnderSafeAreas()
        webView.configureForSandboxEnvironment()
    }

    func extendContentUnderSafeAreas() {
        webView.scrollView.clipsToBounds = false
        view.backgroundColor = webView.underPageBackgroundColor
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
        webView.publisher(for: \.estimatedProgress)
            .sink { [weak self] progress in
                if progress == 1 {
                    self?.progressBar.setProgress(0, animated: false)
                } else {
                    self?.progressBar.setProgress(Float(progress), animated: true)
                }
            }
            .store(in: &subscriptions)

        webView.publisher(for: \.url)
            .sink { [weak self] url in
                guard let self else { return }
                let initialURL = self.viewModel.initialURL
                // avoids infinite loop if the initial url happens to be the nonce retrieval path.
                if url?.absoluteString.contains(WKWebView.wporgNoncePath) == true,
                   initialURL?.absoluteString.contains(WKWebView.wporgNoncePath) != true {
                    self.loadContent()
                } else {
                    self.viewModel.handleRedirect(for: url)
                }
            }
            .store(in: &subscriptions)

        if let siteCredentials, let request = try? webView.authenticateForWPOrg(with: siteCredentials) {
            webView.load(request)
        } else {
            loadContent()
        }
    }
}

// MARK: - Helper methods
private extension AuthenticatedWebViewController {
    func loadContent() {
        guard let url = viewModel.initialURL else {
            return
        }

        /// Authenticate for WP.com automatically if credentials are available.
        ///
        if let wpcomCredentials {
            webView.authenticateForWPComAndRedirect(to: url, credentials: wpcomCredentials)
        } else {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

extension AuthenticatedWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let navigationURL = navigationAction.request.url else {
            return .allow
        }
        return await viewModel.decidePolicy(for: navigationURL)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressBar.setProgress(0, animated: false)
    }
}

extension AuthenticatedWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Allows `target=_blank` links by opening them in the same view, otherwise tapping on these links is no-op.
        // Reference: https://stackoverflow.com/a/25853806/9185596
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
