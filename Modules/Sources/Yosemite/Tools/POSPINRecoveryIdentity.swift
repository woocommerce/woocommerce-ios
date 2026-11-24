import Foundation
import NetworkingCore

public enum POSPINRecoveryIdentity: Equatable, Sendable {
    case sameEligibleAccount
    case differentAccount
    case notEligible
    case failed
    case cleanupFailed

    public static func verifyWordPressCom(authToken: String, expectedUserID: Int64, siteID: Int64) async throws -> Self {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }

        let accountRequest = DotcomRequest(wordpressApiVersion: .mark1_1,
                                           method: .get,
                                           path: "me",
                                           parameters: ["fields": "ID"])
        let accountResponse = try await response(for: accountRequest.asURLRequest(), authorization: "Bearer " + authToken, session: session)
        guard accountResponse.statusCode == 200 else { return .failed }
        let account = try JSONDecoder().decode(AccountID.self, from: accountResponse.data)
        guard account.ID == expectedUserID else { return .differentAccount }

        let rolesRequest = JetpackRequest(wooApiVersion: .none,
                                         method: .get,
                                         siteID: siteID,
                                         path: "wp/v2/users/me",
                                         parameters: ["context": "edit",
                                                      "fields": "id,username,id_wpcom,email,first_name,last_name,nickname,roles"])
        let rolesResponse = try await response(for: rolesRequest.asURLRequest(), authorization: "Bearer " + authToken, session: session)
        guard rolesResponse.statusCode != 403 else { return .notEligible }
        guard rolesResponse.statusCode == 200 else { return .failed }
        let user = try JSONDecoder().decode(SiteUser.self, from: rolesResponse.data)
        return canOpenPOS(roles: user.roles) ? .sameEligibleAccount : .notEligible
    }

    public static func verifySiteCredentials(endpoints: CookieNonceAuthenticationEndpoints,
                                             session: URLSession,
                                             expectedLogin: String) async -> Self {
        do {
            let nonceRequest = URLRequest(url: try endpoints.nonceURL(), cachePolicy: .reloadIgnoringLocalCacheData)
            let nonceResponse = try await response(for: nonceRequest, session: session)
            guard nonceResponse.statusCode == 200,
                  let nonce = CookieNonceAuthenticationRules.validatedNonce(from: nonceResponse.data),
                  var userRequest = siteUserRequest(for: endpoints.siteURL) else { return .failed }
            userRequest.setValue(nonce, forHTTPHeaderField: "X-WP-Nonce")
            let userResponse = try await response(for: userRequest, session: session)
            return siteIdentity(from: userResponse, expectedLogin: expectedLogin)
        } catch {
            return .failed
        }
    }

    public static func verifyBrowserAuthorization(siteURL: String,
                                                  login: String,
                                                  password: String,
                                                  appID: String,
                                                  expectedLogin: String) async -> Self {
        guard let site = URL(string: siteURL),
              let userRequest = siteUserRequest(for: site) else { return .cleanupFailed }
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let authorization = "Basic " + Data((login + ":" + password).utf8).base64EncodedString()
        let userResponse = try? await response(for: userRequest, authorization: authorization, session: session)

        // The approval returns an app_id. WordPress deletes the password by its own UUID.
        guard await removeApplicationPassword(from: site, appID: appID, authorization: authorization, session: session) else {
            return .cleanupFailed
        }
        guard let userResponse else { return .failed }
        return siteIdentity(from: userResponse, expectedLogin: expectedLogin)
    }
}

private extension POSPINRecoveryIdentity {
    struct AccountID: Decodable {
        let ID: Int64
    }

    struct SiteUser: Decodable {
        let username: String?
        let email: String?
        let roles: [String]

        private enum CodingKeys: String, CodingKey {
            case data, username, email, roles
        }

        init(from decoder: Decoder) throws {
            let response = try decoder.container(keyedBy: CodingKeys.self)
            let user = try response.contains(.data) ? response.nestedContainer(keyedBy: CodingKeys.self, forKey: .data) : response
            username = try user.decodeIfPresent(String.self, forKey: .username)
            email = try user.decodeIfPresent(String.self, forKey: .email)
            roles = try user.decode([String].self, forKey: .roles)
        }
    }

    struct StoredApplicationPassword: Decodable {
        let uuid: String
        let appID: String?

        private enum CodingKeys: String, CodingKey {
            case uuid
            case appID = "app_id"
        }
    }

    struct Response {
        let statusCode: Int
        let data: Data
    }

    static func canOpenPOS(roles: [String]) -> Bool {
        roles.compactMap(User.Role.init(rawValue:)).contains { $0.isEligible() }
    }

    static func siteIdentity(from response: Response, expectedLogin: String) -> Self {
        guard response.statusCode == 200, let user = try? JSONDecoder().decode(SiteUser.self, from: response.data) else { return .failed }
        let login = expectedLogin.lowercased()
        guard user.username?.lowercased() == login || user.email?.lowercased() == login else { return .differentAccount }
        return canOpenPOS(roles: user.roles) ? .sameEligibleAccount : .notEligible
    }

    static func siteUserRequest(for site: URL) -> URLRequest? {
        siteRequest(for: site, route: "/wp/v2/users/me", query: [
            URLQueryItem(name: "context", value: "edit"),
            URLQueryItem(name: "_fields", value: "username,email,roles")
        ])
    }

    static func siteRequest(for site: URL, route: String, method: String = "GET", query: [URLQueryItem] = []) -> URLRequest? {
        guard var components = URLComponents(url: site, resolvingAgainstBaseURL: false) else { return nil }
        components.queryItems = [URLQueryItem(name: "rest_route", value: route)] + query
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.httpMethod = method
        return request
    }

    static func response(for request: URLRequest, authorization: String? = nil, session: URLSession) async throws -> Response {
        var request = request
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return Response(statusCode: response.statusCode, data: data)
    }

    static func removeApplicationPassword(from site: URL, appID: String, authorization: String, session: URLSession) async -> Bool {
        let route = "/wp/v2/users/me/application-passwords"
        guard let listRequest = siteRequest(for: site, route: route),
              let list = await cleanupResponse(for: listRequest, authorization: authorization, session: session),
              list.statusCode == 200,
              let passwords = try? JSONDecoder().decode([StoredApplicationPassword].self, from: list.data),
              let password = passwords.first(where: { $0.appID == appID }),
              let deleteRequest = siteRequest(for: site, route: route + "/" + password.uuid, method: "DELETE"),
              let result = await cleanupResponse(for: deleteRequest, authorization: authorization, session: session) else { return false }
        return result.statusCode == 200
    }

    static func cleanupResponse(for request: URLRequest, authorization: String, session: URLSession) async -> Response? {
        if let first = try? await response(for: request, authorization: authorization, session: session), !(500...599).contains(first.statusCode) {
            return first
        }
        return try? await response(for: request, authorization: authorization, session: session)
    }
}
