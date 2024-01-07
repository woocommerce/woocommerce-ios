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

    private let webView = WKWebView()
    private let progressView = WebProgressView()

    private let url: URL

    /// Callback that will be triggered in when the underlying `WKWebView` delegate method `didCommit` is triggered.
    /// This happens when the web view has received data and is starting to render the content.
    ///
    private var onCommit: ((WKWebView) -> Void)?

    /// Check whether to prevent any link clicking to open the link.
    /// This is used in ThemesPreviewView, as it is intended to only display a single demo URL without allowing navigation to
    /// other webpages.
    private var disableLinkClicking: Bool

    private let credentials = ServiceLocator.stores.sessionManager.defaultCredentials

    init(
        isPresented: Binding<Bool>,
        url: URL,
        disableLinkClicking: Bool = false,
        onCommit: ((WKWebView)->Void)? = nil
    ) {
        self._isPresented = isPresented
        self.url = url
        self.disableLinkClicking = disableLinkClicking
        self.onCommit = onCommit
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

        init(_ uiWebView: WebView) {
            parent = uiWebView
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
    }
}
