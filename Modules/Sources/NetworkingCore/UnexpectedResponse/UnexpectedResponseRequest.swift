import Alamofire
import Foundation
import os

final class UnexpectedResponseRequest: Request {
    let original: Request
    private let metadata = OSAllocatedUnfairLock<(status: Int, contentType: String?)?>(initialState: nil)

    init(original: Request) {
        self.original = original
    }

    // The network writes before completion; mappers read on a different queue.
    var responseMetadata: (status: Int, contentType: String?)? {
        metadata.withLock { $0 }
    }

    func recordResponse(status: Int, contentType: String?, tunneled: Bool) {
        metadata.withLock {
            // Outer tunnel metadata does not describe the store's successful response.
            $0 = tunneled ? nil : (status, contentType)
        }
    }

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
            // Some no_response_body envelopes omit an inner status. Only use the
            // transport status when the envelope contains a nonempty store raw_body.
            guard let data, let storeResponse = UnexpectedResponseClassifier.tunnelResponse(in: data, enclosingStatus: status) else { return nil }
            body = storeResponse.data
            responseStatus = storeResponse.status
            mediaType = nil
        }
        if let body, let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
           let code = (json["code"] ?? json["error"]) as? String,
           ["application_passwords_disabled", "application_passwords_disabled_for_user"].contains(code) {
            return ApplicationPasswordUseCaseError.applicationPasswordsDisabled
        }
        let kind = UnexpectedResponseClassifier.classify(data: body, status: responseStatus, contentType: mediaType)
        let failure = kind.map { makeError(kind: $0, status: responseStatus, contentType: mediaType) }
        return failure
    }

    func makeError(kind: UnexpectedStoreResponseError.Kind, status: Int? = nil,
                   contentType: String? = nil, isDecodingFailure: Bool = false) -> UnexpectedStoreResponseError {
        var diagnosticRequest = try? original.asURLRequest()
        if let tunnel = original as? JetpackRequest {
            diagnosticRequest = URL(string: "https://store.invalid/" + tunnel.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
                .map { URLRequest(url: $0) }
            diagnosticRequest?.httpMethod = tunnel.method.rawValue
        }
        let metadata = responseMetadata
        var error = UnexpectedStoreResponseError(kind: kind, statusCode: status ?? metadata?.status,
                                                contentType: contentType ?? metadata?.contentType, request: diagnosticRequest)
        error.isDecodingFailure = isDecodingFailure
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
        let contentType = response.value(forHTTPHeaderField: "Content-Type")
        request.recordResponse(status: response.statusCode, contentType: contentType, tunneled: tunneled)
        return request.responseError(data: data, status: response.statusCode, contentType: contentType, tunneled: tunneled)
    }
}
