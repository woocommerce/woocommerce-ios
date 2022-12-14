import Foundation
import Alamofire

struct RESTRequest: URLRequestConvertible {
    /// URL of the site to make the request with
    ///
    let siteURL: String

    /// HTTP Request Method
    ///
    let method: HTTPMethod

    /// RPC
    ///
    let path: String

    /// Parameters
    ///
    let parameters: [String: Any]?

    /// HTTP Headers
    let headers: [String: String]

    /// A fallback JetpackRequest if the REST request cannot be made with an application password.
    let fallbackRequest: JetpackRequest?

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - method: HTTP Method we should use.
    ///     - path: RPC that should be executed.
    ///     - parameters: Collection of String parameters to be passed over to our target RPC.
    ///
    init(siteURL: String,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any]? = nil,
         headers: [String: String]? = nil,
         fallbackRequest: JetpackRequest?) {
        self.siteURL = siteURL
        self.method = method
        self.path = path
        self.parameters = parameters ?? [:]
        self.headers = headers ?? [:]
        self.fallbackRequest = fallbackRequest
    }

    /// Returns a URLRequest instance representing the current WordPress.com Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let url = try (siteURL + path).asURL()
        let request = try URLRequest(url: url, method: method, headers: headers)

        return try URLEncoding.default.encode(request, with: parameters)
    }
}

extension RESTRequest {
    /// Updates the request headers with authentication information.
    ///
    func updateRequest(with applicationPassword: ApplicationPassword) throws -> URLRequest {
        var request = try asURLRequest()
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let username = "username"
        let password = "password"
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            return request
        }
        let base64LoginString = loginData.base64EncodedString()

        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        return request
    }
}
