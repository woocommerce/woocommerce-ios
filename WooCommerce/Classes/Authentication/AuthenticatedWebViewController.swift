import Combine
import UIKit
import WebKit
import Yosemite
import class Networking.UserAgent
import struct WordPressAuthenticator.WordPressOrgCredentials

/// A web view which is authenticated for WordPress.com, when possible.
///
final class AuthenticatedWebViewController: UIViewController {

    private let currentSite: Site?
    private let viewModel: AuthenticatedWebViewModel
    private let authenticationFlow: WebViewAuthenticationFlow

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .gray
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

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

    private var isFirstNavigation = true

    init(stores: StoresManager = ServiceLocator.stores,
         viewModel: AuthenticatedWebViewModel,
         extraCredentials: Credentials? = nil) {
        self.viewModel = viewModel
        let currentCredentials = stores.sessionManager.defaultCredentials

        let siteCredentials: WordPressOrgCredentials? = {
            if case let .wporg(username, password, siteAddress) = extraCredentials {
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

        let wpcomCredentials: Credentials? = {
            if case .wpcom = extraCredentials {
                return extraCredentials
            } else if case .wpcom = currentCredentials {
                return currentCredentials
            }
            return nil
        }()

        let currentSite = stores.sessionManager.defaultSite

        self.authenticationFlow = {
            guard let currentSite else {
                return WebViewAuthenticationFlow.none
            }
            return viewModel.authenticationFlow(currentSite: currentSite,
                                                wpcomCredentialsAvailable: wpcomCredentials != nil,
                                                wporgCredentialsAvailable: siteCredentials != nil)
        }()
        self.currentSite = currentSite
        self.wpcomCredentials = wpcomCredentials
        self.siteCredentials = siteCredentials

        super.init(nibName: nil, bundle: nil)

        if let initialURL = viewModel.initialURL,
           var viewModel = viewModel as? WebviewReloadable {
            viewModel.reloadWebview = { [weak self] in
                self?.webView.load(.init(url: initialURL))
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureWebView()
        configureActivityIndicator()
        configureProgressBar()
        observeWebView()
        startLoading()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissedInAnyWay {
            viewModel.handleDismissal()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        viewModel.handleDisappear()
        super.viewDidDisappear(animated)
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
    }

    func configureActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: webView.centerYAnchor)
        ])
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

    func observeWebView() {
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
                guard let url else { return }
                self?.handleRedirect(for: url)
            }
            .store(in: &subscriptions)
    }

    /// Authentication logic differs depending on the destination URL and the current site.
    /// More information: pe5sF9-3Si-p2
    ///
    func startLoading() {
        guard let url = viewModel.initialURL else {
            return
        }

        switch authenticationFlow {
        case .wpcom:
            authenticateWPComAndLoadContent(url: url)
        case .jetpackSSO:
            authenticateSSOAndLoadContent(url: url)
        case .siteCredentials:
            authenticateUsingSiteCredentialsAndLoadContent(url: url)
        case .none:
            loadContent(url: url)
        }
    }
}

// MARK: - Helper methods
private extension AuthenticatedWebViewController {
    func authenticateWPComAndLoadContent(url: URL) {
        guard let wpcomCredentials, case .wpcom = wpcomCredentials else {
            return loadContent(url: url)
        }
        do {
            try webView.authenticateForWPComAndRedirect(to: url, credentials: wpcomCredentials)
        } catch {
            loadContent(url: url)
        }
    }

    func authenticateSSOAndLoadContent(url: URL) {
        let tempURL = WooConstants.URLs.wpcomTempRedirectURL.asURL()
        authenticateWPComAndLoadContent(url: tempURL)
    }

    func authenticateUsingSiteCredentialsAndLoadContent(url: URL) {
        guard let siteCredentials, let request = try? webView.authenticateForWPOrg(with: siteCredentials) else {
            return loadContent(url: url)
        }
        webView.load(request)
    }

    func loadContent(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func handleRedirect(for url: URL) {
        guard let initialURL = viewModel.initialURL else {
            return
        }

        switch url.absoluteString {
        case WooConstants.URLs.wpcomTempRedirectURL.rawValue:
            guard let currentSite, let host = URL(string: currentSite.url)?.host else {
                return loadContent(url: initialURL)
            }
            let cookie = HTTPCookie(properties: [
                .domain: host,
                .path: "/",
                .name: Constants.ssoRedirectCookieName,
                .value: initialURL.absoluteString,
            ])

            let queryItem = URLQueryItem(name: Constants.actionParam, value: Constants.jetpackSSOAction)
            guard let cookie, let loginURL = URL(string: currentSite.loginURL)?.appending(queryItems: [queryItem]) else {
                return loadContent(url: initialURL)
            }
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            loadContent(url: loginURL)

        default:
            if url.absoluteString.contains(WKWebView.wporgNoncePath) == true,
               initialURL.absoluteString.contains(WKWebView.wporgNoncePath) != true {
                // Site credentials login completes, now proceed to load the initial URL.
                loadContent(url: initialURL)
            } else {
                viewModel.handleRedirect(for: url)
            }
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

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        defer {
            isFirstNavigation = false
        }
        let response = navigationResponse.response
        if let initialURL = viewModel.initialURL,
           viewModel.isAuthenticationFailure(response: response,
                                             currentSite: currentSite,
                                             authenticationFlow: authenticationFlow,
                                             isFirstNavigation: isFirstNavigation) {
            /// When automatic authentication fails, cancel the navigation and redirect to the original URL instead.
            loadContent(url: initialURL)
            return .cancel
        }
        return await viewModel.decidePolicy(for: response)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressBar.setProgress(0, animated: false)
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        guard let url = webView.url else {
            return
        }
        viewModel.didFinishNavigation(for: url)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        viewModel.didFailProvisionalNavigation(with: error)
        activityIndicator.stopAnimating()
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

private extension AuthenticatedWebViewController {
    enum Constants {
        static let actionParam = "action"
        static let jetpackSSOAction = "jetpack-sso"
        static let ssoRedirectCookieName = "jetpack_sso_redirect_to"
    }
}
