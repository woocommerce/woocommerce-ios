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

        #if DEBUG
        let httpCookie = HTTPCookie(properties: [HTTPCookiePropertyKey.name: "store_sandbox",
                                                 HTTPCookiePropertyKey.value: "[secret",
                                                 HTTPCookiePropertyKey.domain: ".wordpress.com",
                                                 HTTPCookiePropertyKey.path: "/"])
        if let cookie = httpCookie {
            HTTPCookieStorage.shared.setCookies([cookie], for: WooConstants.URLs.loginWPCom.asURL(), mainDocumentURL: nil)
        }
        #endif
        var request = URLRequest(url: WooConstants.URLs.loginWPCom.asURL())
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = true
//        let cookie = String(format: "store_sandbox=@;domain=.wordpress.com;path=/", "[secret]")
//        request.setValue(cookie, forHTTPHeaderField: "Cookie")


        let parameters = ["log": username,
                          "redirect_to": url.absoluteString,
                          "authorization": "Bearer " + token]

        return try URLEncoding.default.encode(request, with: parameters)
    }


    class AuthenticatedWebViewCoordinator: NSObject, WKNavigationDelegate {
        private var parent: AuthenticatedWebView

        init(_ uiWebView: AuthenticatedWebView) {
            parent = uiWebView
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url?.absoluteString, let urlTrigger = parent.urlToTriggerExit, url.contains(urlTrigger) {
                print("TRIGGERED")
                parent.exitTrigger?()
            }
            print("current URL", webView.url)
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
