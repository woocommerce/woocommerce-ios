import Combine
import SwiftUI
import WebKit
import Alamofire
import class Networking.UserAgent

/// Hosting controller for WebView
///
final class WebViewHostingController: UIHostingController<WebView> {
    init(url: URL,
         disableLinkClicking: Bool = false,
         onCommit: ((WKWebView)->Void)? = nil,
         urlToTriggerExit: String? = nil,
         pageLoadHandler: ((URL) -> Void)? = nil,
         redirectHandler: ((URL) -> Void)? = nil,
         errorHandler: ((Error) -> Void)? = nil) {
        super.init(rootView: WebView(isPresented: .constant(true),
                                     url: url,
                                     disableLinkClicking: disableLinkClicking,
                                     onCommit: onCommit,
                                     urlToTriggerExit: urlToTriggerExit,
                                     pageLoadHandler: pageLoadHandler,
                                     redirectHandler: redirectHandler,
                                     errorHandler: errorHandler))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Mirror of AuthenticatedWebView, for equivalent display of URLs in `WKWebView` that do not need authentication on WPCom.
struct WebView: UIViewRepresentable {
    @Environment(\.presentationMode) var presentation
    @Binding var isPresented: Bool {
        didSet {
            if !isPresented {
                presentation.wrappedValue.dismiss()
            }
        }
    }

    let webView = WKWebView()
    private let progressView = WebProgressView()

    private let url: URL

    /// Callback that will be triggered in when the underlying `WKWebView` delegate method `didCommit` is triggered.
    /// This happens when the web view has received data and is starting to render the content.
    ///
    private let onCommit: ((WKWebView) -> Void)?

    /// Check whether to prevent any link clicking to open the link.
    /// This is used in ThemesPreviewView, as it is intended to only display a single demo URL without allowing navigation to
    /// other webpages.
    private let disableLinkClicking: Bool

    /// A url to trigger dismissing of the web view.
    let urlToTriggerExit: String?

    /// Optional closure for when the web page loads the initial URL successfully.
    let pageLoadHandler: ((URL) -> Void)?

    /// Closure to determine the action given the redirect URL.
    /// If `urlToTriggerExit` is provided, this closure is triggered only when
    /// a redirect URL matches `urlToTriggerExit`.
    /// Otherwise, the closure is triggered whenever the web view redirects to a new URL.
    let redirectHandler: ((URL) -> Void)?

    /// Optional closure for when a web page fails to load.
    let errorHandler: ((Error) -> Void)?

    private let credentials = ServiceLocator.stores.sessionManager.defaultCredentials

    init(
        isPresented: Binding<Bool>,
        url: URL,
        disableLinkClicking: Bool = false,
        onCommit: ((WKWebView)->Void)? = nil,
        urlToTriggerExit: String? = nil,
        pageLoadHandler: ((URL) -> Void)? = nil,
        redirectHandler: ((URL) -> Void)? = nil,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.url = url
        self.disableLinkClicking = disableLinkClicking
        self.onCommit = onCommit
        self.urlToTriggerExit = urlToTriggerExit
        self.pageLoadHandler = pageLoadHandler
        self.redirectHandler = redirectHandler
        self.errorHandler = errorHandler
    }

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    func makeUIView(context: Context) -> UIStackView {
        // Webview
        webView.customUserAgent = UserAgent.defaultUserAgent
        webView.navigationDelegate = context.coordinator

        webView.load(URLRequest(url: url))

        // Progress view
        progressView.startedLoading()
        progressView.observeProgress(webView: webView)

        let stackView = UIStackView(arrangedSubviews: [progressView, webView])
        stackView.axis = .vertical
        return stackView
    }

    func updateUIView(_ uiView: UIStackView, context: Context) {
        if let webView = uiView.arrangedSubviews.first(where: { $0 is WKWebView }) as? WKWebView {
            webView.load(URLRequest(url: url))
        }
    }

    class WebViewCoordinator: NSObject, WKNavigationDelegate {
        private var parent: WebView
        private var urlSubscription: AnyCancellable?

        init(_ uiWebView: WebView) {
            parent = uiWebView
            super.init()

            observeURL()
        }

        func observeURL() {
            urlSubscription = parent.webView.publisher(for: \.url)
                .sink { [weak self] url in
                    guard let self, let url else { return }

                    guard let urlToTriggerExit = parent.urlToTriggerExit else {
                        // always trigger `redirectHandler` if `urlToTriggerExit` is not specified.
                        parent.redirectHandler?(url)
                        return
                    }

                    if url.absoluteString.contains(urlToTriggerExit) {
                        parent.redirectHandler?(url)
                    }
                }
        }

        func webView(_ webView: WKWebView, decidePolicyFor
                        navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated && parent.disableLinkClicking {
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.onCommit?(webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url else {
                return
            }
            parent.pageLoadHandler?(url)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.errorHandler?(error)
        }
    }
}
