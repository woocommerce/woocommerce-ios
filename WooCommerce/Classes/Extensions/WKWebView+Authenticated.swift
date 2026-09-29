import Alamofire
import Foundation
import WebKit
import struct WordPressAuthenticator.WordPressOrgCredentials
import struct Yosemite.CookieNonceAuthenticationEndpoints
import enum Yosemite.Credentials
import class Networking.UserAgent

/// An extension to authenticate WPCom automatically
///
extension WKWebView {
    /// Cookie authentication following WordPressKit implementation:
    /// https://github.com/wordpress-mobile/WordPressKit-iOS/blob/trunk/WordPressKit/Authenticator.swift
    ///
    func authenticateForWPOrg(with credentials: WordPressOrgCredentials) throws -> URLRequest {
        guard let endpoints = credentials.authenticationEndpoints else {
            throw AFError.invalidURL(url: credentials.siteURL)
        }
        return try authenticateForWPOrg(with: credentials, authenticationEndpoints: endpoints)
    }

    func authenticateForWPOrg(with credentials: WordPressOrgCredentials,
                              authenticationEndpoints: CookieNonceAuthenticationEndpoints) throws -> URLRequest {
        // WebKit intentionally posts directly to the persisted login entry. Unlike the URLSession login flow, it does not preflight
        // login HTML or discover a transaction-local form action; the navigation gate below constrains every follow-up request instead.
        guard let siteURL = URL(string: credentials.siteURL) else {
            throw AFError.invalidURL(url: credentials.siteURL)
        }
        let credentialIdentity = try CookieNonceAuthenticationEndpoints(siteURL: siteURL)
        guard credentialIdentity.siteURL == authenticationEndpoints.siteURL else {
            throw AFError.invalidURL(url: credentials.siteURL)
        }

        var request = try URLRequest(url: authenticationEndpoints.loginEntryURL, method: .post)
        request.httpShouldHandleCookies = true

        let redirectLink = try authenticationEndpoints.nonceURL().absoluteString
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        let parameters = ["log": credentials.username,
                          "pwd": credentials.password,
                          "redirect_to": redirectLink ?? ""]

        return try URLEncoding.default.encode(request, with: parameters)
    }

    func authenticateForWPComAndRedirect(to url: URL, credentials: Credentials?) throws {
        customUserAgent = UserAgent.defaultUserAgent
        try load(authenticatedPostData(with: credentials, redirectTo: url))
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
}

/// Restricts WebKit navigation while a WordPress.org credential POST is in flight.
struct WPOrgWebViewAuthenticationNavigationGate {
    enum Decision: Equatable {
        case allowCredentialPost
        case allowDestination
        case cancelAndLoadDestination(URL)
        case cancelAndFinish
    }

    enum ResponseDecision: Equatable {
        case allowContinuation
        case allowAndFinish(URL)
        case cancelAndFinish
    }

    private enum Phase {
        case credentialPost
        case destinationAction
        case destinationResponse(URL)
    }

    private let credentialPostURL: URL
    private let expectedNonceURL: URL
    private let expectedAdminBaseURL: URL
    private let authenticationEndpoints: CookieNonceAuthenticationEndpoints
    private var phase = Phase.credentialPost
    private var hasReplacedUnsafeDestinationRequest = false
    private var pendingReplacementURL: URL?
    private var redirectCount = 0
    private var lastApprovedURL: URL?

    init(authenticationRequest: URLRequest,
         authenticationEndpoints: CookieNonceAuthenticationEndpoints) throws {
        guard authenticationRequest.hasMethod(.post),
              authenticationRequest.url == authenticationEndpoints.loginEntryURL else {
            throw AFError.invalidURL(url: authenticationRequest.url?.absoluteString ?? "")
        }
        credentialPostURL = authenticationEndpoints.loginEntryURL
        expectedNonceURL = try authenticationEndpoints.nonceURL()
        expectedAdminBaseURL = try authenticationEndpoints.derivedAdminBaseURL()
        self.authenticationEndpoints = authenticationEndpoints
    }

    mutating func decision(for request: URLRequest, isMainFrame: Bool, shouldPerformDownload: Bool) -> Decision {
        guard isMainFrame, shouldPerformDownload == false, let url = request.url else {
            return .cancelAndFinish
        }

        switch phase {
        case .credentialPost:
            if request.hasMethod(.post),
               url == credentialPostURL {
                phase = .destinationAction
                return .allowCredentialPost
            }
        case .destinationAction, .destinationResponse:
            let previousURL = lastApprovedURL ?? credentialPostURL
            guard let resolvedURL = try? authenticationEndpoints.resolveRedirect(
                location: url.absoluteString,
                from: previousURL
            ),
                  resolvedURL == url,
                  isExpectedDestination(url) else {
                return .cancelAndFinish
            }
            let hasBody = request.httpBody != nil || request.httpBodyStream != nil
            let isCleanGet = request.hasMethod(.get) && hasBody == false
            if let pendingReplacementURL {
                guard url == pendingReplacementURL, isCleanGet else {
                    return .cancelAndFinish
                }
                self.pendingReplacementURL = nil
                phase = .destinationResponse(url)
                lastApprovedURL = url
                return .allowDestination
            }
            guard redirectCount < CookieNonceAuthenticationEndpoints.maximumRedirectCount else {
                return .cancelAndFinish
            }
            redirectCount += 1
            if isCleanGet {
                phase = .destinationResponse(url)
                lastApprovedURL = url
                return .allowDestination
            }
            if hasReplacedUnsafeDestinationRequest == false,
               request.hasMethod(.post) || hasBody {
                hasReplacedUnsafeDestinationRequest = true
                pendingReplacementURL = url
                return .cancelAndLoadDestination(url)
            }
        }
        return .cancelAndFinish
    }

    mutating func decision(
        for response: URLResponse,
        isMainFrame: Bool,
        canShowMIMEType: Bool
    ) -> ResponseDecision {
        guard isMainFrame,
              let response = response as? HTTPURLResponse,
              let responseURL = response.url else {
            return .cancelAndFinish
        }

        switch phase {
        case .credentialPost:
            return .cancelAndFinish
        case .destinationAction:
            guard responseURL == credentialPostURL,
                  300..<400 ~= response.statusCode else {
                return .cancelAndFinish
            }
            return .allowContinuation
        case .destinationResponse(let expectedURL):
            if responseURL == expectedURL,
               200..<300 ~= response.statusCode,
               canShowMIMEType {
                return .allowAndFinish(expectedURL)
            }
            guard responseURL == expectedURL,
                  300..<400 ~= response.statusCode else {
                return .cancelAndFinish
            }
            return .allowContinuation
        }
    }

    /// The two destinations the credential POST may reach: the derived nonce endpoint and the admin base.
    ///
    /// The `afterLoginAt: url` checks are deliberately self-referential: they re-derive the endpoints as if the login
    /// transaction ended at `url`, which admits the default-port HTTP-to-HTTPS promoted variants on an `http` site.
    /// Same host and scheme upgrades only — a downgrade is already rejected by `resolveRedirect` before this runs.
    func isExpectedDestination(_ url: URL) -> Bool {
        url == expectedNonceURL ||
            url == expectedAdminBaseURL ||
            authenticationEndpoints.isExpectedNonceURL(url, afterLoginAt: url) ||
            authenticationEndpoints.isExpectedAdminBaseURL(url, afterLoginAt: url)
    }
}

private extension URLRequest {
    /// Case-insensitive HTTP method comparison, since WebKit may surface a differently cased method than it was given.
    func hasMethod(_ method: HTTPMethod) -> Bool {
        httpMethod?.uppercased() == method.rawValue.uppercased()
    }
}
