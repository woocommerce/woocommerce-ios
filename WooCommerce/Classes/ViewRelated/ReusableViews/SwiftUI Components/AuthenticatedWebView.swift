import SwiftUI
import WebKit
import Alamofire

// Bridge UIKit `WKWebView` component to SwiftUI for URLs that need authentication on WPCom
struct AuthenticatedWebView: UIViewRepresentable {
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

    func makeCoordinator() -> AuthenticatedWebViewCoordinator {
        AuthenticatedWebViewCoordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.navigationDelegate = context.coordinator

        configureForSandboxEnvironment(webview)

        do {
            try webview.load(authenticatedPostData())
        } catch {
            DDLogError("# error: Cannot be able to load the authenticated web view on WPCom")
        }
        return webview
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {

    }

    private func authenticatedPostData() throws -> URLRequest {
        guard let username = credentials?.username,
              let token = credentials?.authToken else {
            return URLRequest(url: url)
        }

        var request = URLRequest(url: WooConstants.URLs.loginWPCom.asURL())
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = true

        let parameters = ["log": username,
                          "redirect_to": url.absoluteString,
                          "authorization": "Bearer " + token]

        return try URLEncoding.default.encode(request, with: parameters)
    }

    /// For all test cases, to test against the staging server
    /// please apply the following patch after replacing [secret] with a sandbox secret from the secret store.
    ///
    private func configureForSandboxEnvironment(_ webview: WKWebView) {
        #if DEBUG
        if let cookie = HTTPCookie(properties: [
            .domain: ".wordpress.com",
            .path: "/",
            .name: "store_sandbox",
            .value: "[secret]",
            .secure: "TRUE"
        ]) {
            webview.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
            }
        }
        #endif
    }

    class AuthenticatedWebViewCoordinator: NSObject, WKNavigationDelegate {
        private var parent: AuthenticatedWebView

        init(_ uiWebView: AuthenticatedWebView) {
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



#if DEBUG
struct AuthenticatedWebView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedWebView(isPresented: .constant(true),
                             url: URL(string: "https://www.woocommerce.com")!)
    }
}
#endif
