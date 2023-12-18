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

    let url: URL

    /// Optional URL or part of URL to trigger exit
    ///
    var urlToTriggerExit: String?

    /// Callback that will be triggered if the destination url containts the `urlToTriggerExit`
    ///
    var exitTrigger: (() -> Void)?

    private let credentials = ServiceLocator.stores.sessionManager.defaultCredentials

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.customUserAgent = UserAgent.defaultUserAgent
        webview.navigationDelegate = context.coordinator

        webview.load(URLRequest(url: url))
        return webview
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {

    }

    class WebViewCoordinator: NSObject, WKNavigationDelegate {
        private var parent: WebView

        init(_ uiWebView: WebView) {
            parent = uiWebView
        }

        func webView(_ webView: WKWebView, decidePolicyFor
                        navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = webView.url?.absoluteString, let urlTrigger = parent.urlToTriggerExit, url.contains(urlTrigger) {
                parent.exitTrigger?()
                decisionHandler(.cancel)
                webView.navigationDelegate = nil
                return
            }
            decisionHandler(.allow)
        }
    }
}
