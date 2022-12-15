import Foundation
import Alamofire

/// Wraps up a URLRequestConvertible Instance, and injects the Authorization + User Agent whenever the actual Request is required.
///
struct RESTRequest: Request {
    
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

    /// A fallback JetpackRequest if the REST request cannot be made with an application password.
    let fallbackRequest: JetpackRequest?

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///     - fallbackRequest: A fallback Jetpack request to trigger if the REST request cannot be made.
    ///
    init(siteURL: String,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any] = [:],
         fallbackRequest: JetpackRequest?) {
        self.siteURL = siteURL
        self.method = method
        self.path = path
        self.parameters = parameters
        self.fallbackRequest = fallbackRequest
    }

    init(siteURL: String, fallbackRequest: JetpackRequest) {
        self.init(siteURL: siteURL,
                  method: fallbackRequest.method,
                  path: fallbackRequest.path,
                  parameters: fallbackRequest.parameters,
                  fallbackRequest: fallbackRequest)
    }

    /// Returns a URLRequest instance representing the current REST API Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let url = try (siteURL + path).asURL()
        let request = try URLRequest(url: url, method: method)

        return try URLEncoding.default.encode(request, with: parameters)
    }

    func responseDataValidator() -> ResponseDataValidator {
        DummyResponseDataValidator()
    }
}

extension RESTRequest {
    /// Updates the request headers with authentication information.
    ///
    func authenticateRequest(with applicationPassword: ApplicationPassword) throws -> URLRequest {
        var request = try asURLRequest()
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let username = applicationPassword.wpOrgUsername
        let password = applicationPassword.wpOrgUsername
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            return request
        }
        let base64LoginString = loginData.base64EncodedString()

        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        return request
    }
}
