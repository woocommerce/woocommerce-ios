import Alamofire
import Foundation
import WebKit
import struct WordPressAuthenticator.WordPressOrgCredentials
import enum Yosemite.Credentials
import class Networking.UserAgent

/// An extension to authenticate WPCom automatically
///
extension WKWebView {
    static let wporgNoncePath = "/admin-ajax.php?action=rest-nonce"

    /// Cookie authentication following WordPressKit implementation:
    /// https://github.com/wordpress-mobile/WordPressKit-iOS/blob/trunk/WordPressKit/Authenticator.swift
    ///
    func authenticateForWPOrg(with credentials: WordPressOrgCredentials) throws -> URLRequest {
        var request = try URLRequest(url: credentials.loginURL.asURL(), method: .post)
        request.httpShouldHandleCookies = true

        let redirectLink = (credentials.adminURL + Self.wporgNoncePath)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        let parameters = ["log": credentials.username,
                          "pwd": credentials.password,
                          "redirect_to": redirectLink ?? ""]

        return try URLEncoding.default.encode(request, with: parameters)
    }

    func authenticateForWPComAndRedirect(to url: URL, credentials: Credentials?) {
        customUserAgent = UserAgent.defaultUserAgent
        do {
            try load(authenticatedPostData(with: credentials, redirectTo: url))
        } catch {
            DDLogError("⛔️ Cannot load the authenticated web view on WPCom")
        }
    }

    private func authenticatedPostData(with credentials: Credentials?, redirectTo url: URL) throws -> URLRequest {
        guard case let .wpcom(username, token, _) = credentials else {
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
    func configureForSandboxEnvironment() {
#if DEBUG
        if let cookie = HTTPCookie(properties: [
            .domain: ".wordpress.com",
            .path: "/",
            .name: "store_sandbox",
            .value: "[secret]",
            .secure: "TRUE"
        ]) {
            configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
            }
        }
#endif
    }
}
