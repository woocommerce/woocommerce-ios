import Alamofire
import Foundation
import WebKit
import struct Yosemite.Credentials
import class Networking.UserAgent

/// An extension to authenticate WPCom automatically
///
extension WKWebView {
    func authenticateForWPComAndRedirect(to url: URL, credentials: Credentials?) {
        customUserAgent = UserAgent.defaultUserAgent
        do {
            try load(authenticatedPostData(with: credentials, redirectTo: url))
        } catch {
            DDLogError("⛔️ Cannot load the authenticated web view on WPCom")
        }
    }

    private func authenticatedPostData(with credentials: Credentials?, redirectTo url: URL) throws -> URLRequest {
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
}
