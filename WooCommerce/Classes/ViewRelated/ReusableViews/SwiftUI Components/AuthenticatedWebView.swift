import SwiftUI
import WebKit
import Foundation
import Alamofire

// MARK: - AuthenticatedWebViewDelegate
// For handling values received from webview
protocol AuthenticatedWebViewDelegate {
    func exitTriggered()
}

// Bridge UIKit `WKWebView` component to SwiftUI for URLs that need authentication on WPCom
struct AuthenticatedWebView: UIViewRepresentable, AuthenticatedWebViewDelegate {

    func exitTriggered() {

    }

    let url: URL

    /// Optional URL or part of URL to trigger exit
    var urlToTriggerExit: String?

    let credentials = ServiceLocator.stores.sessionManager.defaultCredentials

    func makeCoordinator() -> AuthenticatedWebViewCoordinator {
        AuthenticatedWebViewCoordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.navigationDelegate = context.coordinator
        return webview
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        print("USERNAME: ", credentials!.username)
        print("URL: ", url.absoluteString)
        print("TOKEN: ", credentials!.authToken)
        //        request?.httpMethod = "POST"
        //        request.httpBody = authenticatedPostData().data(using: .utf8)
        do {
            try uiView.load(authenticatedPostData())
        } catch {
            DDLogError("# error: Cannot be able to load the authenticated web view on WPCom")
        }
    }

    private func authenticatedPostData() throws -> URLRequest {
        guard let username = credentials?.username,
              let token = credentials?.authToken else {
            return URLRequest(url: url)
        }

        var request = URLRequest(url: WooConstants.URLs.loginWPCom.asURL())
        request.httpMethod = "POST"
        let parameters = ["log": username,
                          "redirect_to": url.absoluteString,
                          "authorization": "Bearer " + token]

        return try URLEncoding.default.encode(request, with: parameters)
    }


    class AuthenticatedWebViewCoordinator: NSObject, WKNavigationDelegate {
        private var parent: AuthenticatedWebView
        private var delegate: AuthenticatedWebViewDelegate?

        init(_ uiWebView: AuthenticatedWebView) {
            parent = uiWebView
            delegate = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

            if let url = webView.url?.absoluteString, let urlTrigger = parent.urlToTriggerExit, url.contains(urlTrigger) {
                print("TRIGGERED")
                delegate?.exitTriggered()
            }
            print("current URL", webView.url)
        }
    }
}



#if DEBUG
struct AuthenticatedWebView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedWebView(url: URL(string: "https://www.woocommerce.com")!)
    }
}
#endif
