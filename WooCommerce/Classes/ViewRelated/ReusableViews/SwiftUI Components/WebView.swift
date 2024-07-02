import Combine
import SwiftUI
import WebKit
import Alamofire
import class Networking.UserAgent

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

    let urlToTriggerExit: String?
    let exitTrigger: ((URL?) -> Void)?

    private let credentials = ServiceLocator.stores.sessionManager.defaultCredentials

    init(
        isPresented: Binding<Bool>,
        url: URL,
        disableLinkClicking: Bool = false,
        onCommit: ((WKWebView)->Void)? = nil,
        urlToTriggerExit: String? = nil,
        exitTrigger: ((URL?) -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.url = url
        self.disableLinkClicking = disableLinkClicking
        self.onCommit = onCommit
        self.urlToTriggerExit = urlToTriggerExit
        self.exitTrigger = exitTrigger
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
                    DDLogDebug("🧭 Current URL: \(url.absoluteString)")
                    if let urlToTriggerExit = parent.urlToTriggerExit,
                        url.absoluteString.contains(urlToTriggerExit) {
                        parent.exitTrigger?(url)
                    } else {
                        parent.exitTrigger?(url)
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
    }
}
