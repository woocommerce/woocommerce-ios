import CocoaLumberjackSwift
import Foundation

/// Maps the `GET /wc-pos/v1/staff` response, handling both:
/// - Jetpack tunnel `{"data": {...}}` envelope
/// - Direct REST `{...}` response
/// - WC REST error `{"code": "...", "message": "..."}`
/// - WC REST error wrapped in Jetpack envelope `{"data": {"code": "...", ...}}`
struct POSStaffMapper: Mapper {
    typealias Output = [POSStaffMember]

    func map(response: Data) throws -> [POSStaffMember] {
        let container = try mapPOSStaffResponse(response,
                                                decodeDirect: POSStaffListResponse.self,
                                                decodeEnvelope: POSStaffListResponseEnvelope.self)
        return container.staff
    }
}

// MARK: - Shared decoding pipeline

/// Protocol describing a Jetpack tunnel envelope that wraps a decoded inner value under the `data` key.
private protocol POSDataEnvelope: Decodable {
    associatedtype Inner: Decodable
    var data: Inner { get }
}

/// Tries all known POS response formats in sequence. Throws a descriptive error when nothing works.
private func mapPOSStaffResponse<Direct: Decodable, Envelope: POSDataEnvelope>(
    _ response: Data,
    decodeDirect: Direct.Type,
    decodeEnvelope: Envelope.Type
) throws -> Direct where Envelope.Inner == Direct {
    let decoder = JSONDecoder()

    // 1. WC REST error at root.
    if let wcError = try? decoder.decode(WCRESTError.self, from: response),
       wcError.code != nil {
        throw mapWCError(wcError)
    }

    // 2. WC REST error wrapped in a Jetpack envelope.
    if let envelope = try? decoder.decode(WCRESTErrorEnvelope.self, from: response),
       envelope.data.code != nil {
        throw mapWCError(envelope.data)
    }

    // 3. Jetpack envelope with success body.
    if let envelope = try? decoder.decode(Envelope.self, from: response) {
        return envelope.data
    }

    // 4. Direct success body.
    if let direct = try? decoder.decode(Direct.self, from: response) {
        return direct
    }

    let preview = responsePreview(response)
    DDLogError("<> POS staff mapper could not decode response. Preview: \(preview)")
    throw POSAuthError.malformedResponse(preview: preview)
}

private func responsePreview(_ data: Data) -> String {
    let maxLength = 500
    guard let string = String(data: data, encoding: .utf8) else {
        return "<non-utf8 body, \(data.count) bytes>"
    }
    if string.count <= maxLength {
        return string
    }
    return String(string.prefix(maxLength)) + "…(truncated, total \(data.count) bytes)"
}

private struct POSStaffListResponseEnvelope: POSDataEnvelope {
    let data: POSStaffListResponse
}

// MARK: - WC REST Error

private struct WCRESTErrorEnvelope: Decodable {
    let data: WCRESTError
}

private struct WCRESTError: Decodable {
    let code: String?
    let message: String?
}

private func mapWCError(_ wcError: WCRESTError) -> POSAuthError {
    let code = wcError.code ?? "unknown"
    let message = wcError.message ?? "Unknown error"
    return .unknown(code: code, message: message)
}
