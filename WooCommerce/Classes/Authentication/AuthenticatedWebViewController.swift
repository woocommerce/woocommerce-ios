import Combine
import UIKit
import WebKit
import Yosemite
import class Networking.UserAgent
import struct WordPressAuthenticator.WordPressOrgCredentials

struct WPOrgWebViewAuthenticationContext {
    let credentials: WordPressOrgCredentials
    let authenticationEndpoints: CookieNonceAuthenticationEndpoints
}

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
    private let webView: WKWebView

    /// Progress bar for the web view
    private lazy var progressBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    /// Strong reference for the subscription to update progress bar
    private var subscriptions: Set<AnyCancellable> = []

    private let siteAuthentication: WPOrgWebViewAuthenticationContext?

    private let wpcomCredentials: Credentials?

    private let siteCredentialReplacementScheduler: (@escaping () -> Void) -> Void

    private var isFirstNavigation = true
    private var siteCredentialNavigationGate: WPOrgWebViewAuthenticationNavigationGate?
    private var siteCredentialNavigation: WKNavigation?
    private var siteCredentialNavigationExpectedToCancel: WKNavigation?
    private var siteCredentialReplacementLoadID: UUID?

    convenience init(stores: StoresManager = ServiceLocator.stores,
                     viewModel: AuthenticatedWebViewModel,
                     extraCredentials: Credentials? = nil) {
        self.init(stores: stores,
                  viewModel: viewModel,
                  extraCredentials: extraCredentials,
                  webView: WKWebView(frame: .zero))
    }

    /// Hosts a JS-initiated popup web view supplied by WebKit's `createWebViewWith`.
    /// The supplied web view must keep the `WKWebViewConfiguration` provided by WebKit.
    convenience init(popupWebView: WKWebView) {
        self.init(stores: ServiceLocator.stores,
                  viewModel: PopupAuthenticatedWebViewModel(),
                  extraCredentials: nil,
                  webView: popupWebView)
    }

    init(stores: StoresManager,
         viewModel: AuthenticatedWebViewModel,
         extraCredentials: Credentials?,
         webView: WKWebView,
         siteCredentialReplacementScheduler: @escaping (@escaping () -> Void) -> Void = { work in
             DispatchQueue.main.async(execute: work)
         }) {
        self.viewModel = viewModel
        self.webView = webView
        self.siteCredentialReplacementScheduler = siteCredentialReplacementScheduler
        let currentCredentials = stores.sessionManager.defaultCredentials

        let siteAuthentication = Self.resolveWPOrgAuthentication(
            extraCredentials: extraCredentials,
            currentCredentials: currentCredentials,
            authenticationEndpointLookup: stores.sessionManager.cookieNonceAuthenticationEndpoints(for:)
        )

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
                                                wporgCredentialsAvailable: siteAuthentication != nil)
        }()
        self.currentSite = currentSite
        self.wpcomCredentials = wpcomCredentials
        self.siteAuthentication = siteAuthentication

        super.init(nibName: nil, bundle: nil)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.customUserAgent = UserAgent.defaultUserAgent
        webView.navigationDelegate = self
        webView.uiDelegate = self

        if let initialURL = viewModel.initialURL,
           var viewModel = viewModel as? WebviewReloadable {
            viewModel.reloadWebview = { [weak self] in
                self?.finishSiteCredentialAuthentication()
                self?.webView.stopLoading()
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
            finishSiteCredentialAuthentication()
            webView.stopLoading()
            viewModel.handleDismissal()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        viewModel.handleDisappear()
        super.viewDidDisappear(animated)
    }
}

extension AuthenticatedWebViewController {
    static func resolveWPOrgAuthentication(
        extraCredentials: Credentials?,
        currentCredentials: Credentials?,
        authenticationEndpointLookup: (Credentials) -> CookieNonceAuthenticationEndpoints?
    ) -> WPOrgWebViewAuthenticationContext? {
        let selectedCredentials: Credentials?
        if case .wporg = extraCredentials {
            selectedCredentials = extraCredentials
        } else if case .wporg = currentCredentials {
            selectedCredentials = currentCredentials
        } else {
            selectedCredentials = nil
        }

        guard let selectedCredentials,
              case let .wporg(username, password, siteAddress) = selectedCredentials else {
            return nil
        }
        let credentials = WordPressOrgCredentials(
            username: username,
            password: password,
            xmlrpc: siteAddress + "/xmlrpc.php",
            options: [:]
        )
        guard let endpoints = authenticationEndpointLookup(selectedCredentials) ?? credentials.authenticationEndpoints else {
            return nil
        }
        return WPOrgWebViewAuthenticationContext(credentials: credentials, authenticationEndpoints: endpoints)
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
        guard let siteAuthentication else {
            return loadContent(url: url)
        }
        do {
            let request = try webView.authenticateForWPOrg(
                with: siteAuthentication.credentials,
                authenticationEndpoints: siteAuthentication.authenticationEndpoints
            )
            siteCredentialNavigationGate = try WPOrgWebViewAuthenticationNavigationGate(
                authenticationRequest: request,
                authenticationEndpoints: siteAuthentication.authenticationEndpoints
            )
            siteCredentialNavigation = webView.load(request)
        } catch {
            finishSiteCredentialAuthentication()
            loadContent(url: url)
        }
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
            if siteCredentialNavigationGate != nil {
                return
            }
            viewModel.handleRedirect(for: url)
        }
    }

    func finishSiteCredentialAuthentication() {
        siteCredentialNavigationGate = nil
        siteCredentialNavigation = nil
        siteCredentialNavigationExpectedToCancel = nil
        siteCredentialReplacementLoadID = nil
    }

    func failSiteCredentialAuthenticationAndLoadInitialURL() {
        guard siteCredentialNavigationGate != nil else {
            return
        }
        finishSiteCredentialAuthentication()
        webView.stopLoading()
        if let initialURL = viewModel.initialURL {
            loadContent(url: initialURL)
        }
    }
}

extension AuthenticatedWebViewController {
    func decideSiteCredentialNavigation(
        for request: URLRequest,
        isMainFrame: Bool,
        shouldPerformDownload: Bool
    ) -> WKNavigationActionPolicy? {
        guard var gate = siteCredentialNavigationGate else {
            return nil
        }
        let decision = gate.decision(
            for: request,
            isMainFrame: isMainFrame,
            shouldPerformDownload: shouldPerformDownload
        )
        siteCredentialNavigationGate = gate
        switch decision {
        case .allowCredentialPost, .allowDestination:
            return .allow
        case .cancelAndLoadDestination(let destinationURL):
            scheduleSiteCredentialReplacementLoad(destinationURL)
            return .cancel
        case .cancelAndFinish:
            failSiteCredentialAuthenticationAndLoadInitialURL()
            return .cancel
        }
    }

    func decideSiteCredentialNavigation(
        for response: URLResponse,
        isMainFrame: Bool,
        canShowMIMEType: Bool
    ) -> WKNavigationResponsePolicy? {
        guard var gate = siteCredentialNavigationGate else {
            return nil
        }
        let decision = gate.decision(
            for: response,
            isMainFrame: isMainFrame,
            canShowMIMEType: canShowMIMEType
        )
        siteCredentialNavigationGate = gate
        switch decision {
        case .allowContinuation:
            return .allow
        case .allowAndFinish(let destinationURL):
            finishSiteCredentialAuthentication()
            if viewModel.initialURL == destinationURL {
                return .allow
            }
            webView.stopLoading()
            if let initialURL = viewModel.initialURL {
                loadContent(url: initialURL)
            }
            return .cancel
        case .cancelAndFinish:
            failSiteCredentialAuthenticationAndLoadInitialURL()
            return .cancel
        }
    }

    private func scheduleSiteCredentialReplacementLoad(_ destinationURL: URL) {
        siteCredentialNavigationExpectedToCancel = siteCredentialNavigation
        let loadID = UUID()
        siteCredentialReplacementLoadID = loadID
        siteCredentialReplacementScheduler { [weak self] in
            guard let self,
                  self.siteCredentialNavigationGate != nil,
                  self.siteCredentialReplacementLoadID == loadID else {
                return
            }
            self.siteCredentialReplacementLoadID = nil
            self.siteCredentialNavigation = self.webView.load(URLRequest(url: destinationURL))
        }
    }

    private func shouldSuppressSiteCredentialCancellation(for navigation: WKNavigation?, error: Error) -> Bool {
        let error = error as NSError
        guard let expectedNavigation = siteCredentialNavigationExpectedToCancel,
              error.domain == NSURLErrorDomain,
              error.code == NSURLErrorCancelled,
              navigation === expectedNavigation else {
            return false
        }
        siteCredentialNavigationExpectedToCancel = nil
        return true
    }
}

extension AuthenticatedWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if let policy = decideSiteCredentialNavigation(
            for: navigationAction.request,
            isMainFrame: navigationAction.targetFrame?.isMainFrame == true,
            shouldPerformDownload: navigationAction.shouldPerformDownload
        ) {
            return policy
        }

        guard let navigationURL = navigationAction.request.url else {
            return .allow
        }

        let policy = await viewModel.decidePolicy(for: navigationURL)
        return policy
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        defer {
            isFirstNavigation = false
        }
        let response = navigationResponse.response
        if let policy = decideSiteCredentialNavigation(
            for: response,
            isMainFrame: navigationResponse.isForMainFrame,
            canShowMIMEType: navigationResponse.canShowMIMEType
        ) {
            return policy
        }
        if let initialURL = viewModel.initialURL,
           viewModel.isAuthenticationFailure(response: response,
                                             currentSite: currentSite,
                                             authenticationFlow: authenticationFlow,
                                             isFirstNavigation: isFirstNavigation) {
            /// When automatic authentication fails, cancel the navigation and redirect to the original URL instead.
            if siteCredentialNavigationGate != nil {
                failSiteCredentialAuthenticationAndLoadInitialURL()
            } else {
                loadContent(url: initialURL)
            }
            return .cancel
        }
        let policy = await viewModel.decidePolicy(for: response)
        switch policy {
        case .allow:
            break
        default:
            finishSiteCredentialAuthentication()
        }
        return policy
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if siteCredentialNavigationGate != nil,
           navigation !== siteCredentialNavigationExpectedToCancel {
            siteCredentialNavigation = navigation
        }
        progressBar.setProgress(0, animated: false)
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        guard let url = webView.url else {
            failSiteCredentialAuthenticationAndLoadInitialURL()
            return
        }
        if siteCredentialNavigationGate != nil {
            failSiteCredentialAuthenticationAndLoadInitialURL()
            return
        }
        viewModel.didFinishNavigation(for: url)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        guard shouldSuppressSiteCredentialCancellation(for: navigation, error: error) == false else {
            return
        }
        failSiteCredentialAuthenticationAndLoadInitialURL()
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard shouldSuppressSiteCredentialCancellation(for: navigation, error: error) == false else {
            return
        }
        failSiteCredentialAuthenticationAndLoadInitialURL()
        viewModel.didFailProvisionalNavigation(with: error)
        activityIndicator.stopAnimating()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        failSiteCredentialAuthenticationAndLoadInitialURL()
    }
}

extension AuthenticatedWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Use the delegate-supplied `configuration` verbatim so the popup preserves the `window.opener` relationship.
        return presentPopupWebView(with: configuration, for: navigationAction)
    }

    func webViewDidClose(_ webView: WKWebView) {
        dismiss(animated: true)
    }
}

private extension AuthenticatedWebViewController {
    func presentPopupWebView(with configuration: WKWebViewConfiguration,
                             for navigationAction: WKNavigationAction) -> WKWebView? {
        guard navigationAction.targetFrame == nil else {
            return nil
        }

        let childWebView = WKWebView(frame: .zero, configuration: configuration)
        let popupViewController = AuthenticatedWebViewController(popupWebView: childWebView)
        popupViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak popupViewController] _ in
                popupViewController?.dismiss(animated: true)
            }
        )
        let navigationController = UINavigationController(rootViewController: popupViewController)
        navigationController.modalPresentationStyle = .pageSheet
        topmostViewController().present(navigationController, animated: true)

        // WebKit loads `navigationAction.request` into the returned web view itself.
        return childWebView
    }

    func topmostViewController() -> UIViewController {
        var viewController: UIViewController = self
        while let presented = viewController.presentedViewController {
            viewController = presented
        }
        return viewController
    }
}

private extension AuthenticatedWebViewController {
    enum Constants {
        static let actionParam = "action"
        static let jetpackSSOAction = "jetpack-sso"
        static let ssoRedirectCookieName = "jetpack_sso_redirect_to"
    }
}

/// No-op view model used when the controller hosts a JS-initiated popup web view.
private final class PopupAuthenticatedWebViewModel: AuthenticatedWebViewModel {
    let title = ""
    let initialURL: URL? = nil
    func handleDismissal() {}
    func handleRedirect(for url: URL?) {}
    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy { .allow }
}
