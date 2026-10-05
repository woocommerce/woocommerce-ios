import Alamofire
import Foundation

/// Opt-in metadata; the wrapped request still controls conversion, authentication and validation.
struct UnexpectedResponseRequest: Request {
    let original: Request

    func asURLRequest() throws -> URLRequest { try original.asURLRequest() }
    func responseDataValidator() -> ResponseDataValidator { original.responseDataValidator() }

    static func wrap(_ request: Request, enabled: Bool) -> Request {
        enabled ? UnexpectedResponseRequest(original: request) : request
    }

    func responseError(data: Data?, status: Int, contentType: String? = nil, tunneled: Bool) -> Error? {
        var body = data
        var responseStatus = status
        var mediaType = contentType
        if tunneled {
            guard let data, let storeResponse = UnexpectedResponseClassifier.tunnelResponse(in: data) else { return nil }
            body = storeResponse.data
            responseStatus = storeResponse.status
            mediaType = nil
        }
        let kind = UnexpectedResponseClassifier.classify(data: body, status: responseStatus, contentType: mediaType)
        let failure = kind.map { makeError(kind: $0, data: body, status: responseStatus, contentType: mediaType) }
        // Known feature restrictions retain their business handling even when diagnostics classify a 501.
        if let body, let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
           let code = (json["code"] ?? json["error"]) as? String,
           ["application_passwords_disabled", "application_passwords_disabled_for_user"].contains(code) {
            return ApplicationPasswordUseCaseError.applicationPasswordsDisabled
        }
        return failure
    }

    func makeError(kind: UnexpectedStoreResponseError.Kind, data: Data?, status: Int? = nil,
                   contentType: String? = nil) -> UnexpectedStoreResponseError {
        var diagnosticRequest = try? original.asURLRequest()
        if let tunnel = original as? JetpackRequest {
            diagnosticRequest = URL(string: "https://store.invalid/" + tunnel.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
                .map { URLRequest(url: $0) }
            diagnosticRequest?.httpMethod = tunnel.method.rawValue
        }
        let error = UnexpectedStoreResponseError(kind: kind, statusCode: status, data: data,
                                                contentType: contentType, request: diagnosticRequest)
        DDLogWarn(error.logMessage)
        return error
    }
}

extension URLRequestConvertible {
    var originalResponseRequest: URLRequestConvertible {
        (self as? UnexpectedResponseRequest)?.original ?? self
    }
}

extension Alamofire.DataResponse {
    func unexpectedResponseError(for request: URLRequestConvertible, tunneled: Bool) -> Error? {
        guard let request = request as? UnexpectedResponseRequest, let response,
              error?.asAFError?.isSessionTaskError != true,
              error?.asAFError?.isRequestRetryError != true else { return nil }
        return request.responseError(data: data, status: response.statusCode,
                                     contentType: response.value(forHTTPHeaderField: "Content-Type"), tunneled: tunneled)
    }
}
