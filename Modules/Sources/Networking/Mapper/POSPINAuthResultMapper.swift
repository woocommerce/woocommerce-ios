import CocoaLumberjackSwift
import Foundation

/// Maps a PIN auth response, handling both:
/// - Jetpack tunnel `{"data": {...}}` envelope
/// - Direct REST `{...}` response
/// - WC REST error `{"code": "...", "message": "...", "data": {"status": N}}`
/// - WC REST error wrapped in Jetpack envelope `{"data": {"code": "...", ...}}`
///
/// The decode strategy cascades: it attempts each known format, and if every
/// strategy fails it surfaces a `POSAuthError.malformedResponse` that includes
/// a short preview of the raw body to make debugging easier.
struct POSPINAuthResultMapper: Mapper {
    typealias Output = POSPINAuthResult

    func map(response: Data) throws -> POSPINAuthResult {
        try mapPOSResponse(response, decodeDirect: POSPINAuthResult.self, decodeEnvelope: POSPINAuthResultEnvelope.self)
    }
}

/// Maps an approval response with the same envelope/error handling.
struct POSApprovalResultMapper: Mapper {
    typealias Output = POSApprovalResult

    func map(response: Data) throws -> POSApprovalResult {
        try mapPOSResponse(response, decodeDirect: POSApprovalResult.self, decodeEnvelope: POSApprovalResultEnvelope.self)
    }
}

/// Maps a staff status response.
struct POSStaffStatusMapper: Mapper {
    typealias Output = [POSStaffUser]

    func map(response: Data) throws -> [POSStaffUser] {
        let container = try mapPOSResponse(response,
                                           decodeDirect: POSStaffStatusResponse.self,
                                           decodeEnvelope: POSStaffStatusResponseEnvelope.self)
        return container.users
    }
}

/// Maps a PIN verify response with the same envelope/error handling.
struct POSPINVerifyResultMapper: Mapper {
    typealias Output = POSPINVerifyResult

    func map(response: Data) throws -> POSPINVerifyResult {
        try mapPOSResponse(response, decodeDirect: POSPINVerifyResult.self, decodeEnvelope: POSPINVerifyResultEnvelope.self)
    }
}

// MARK: - Shared decoding pipeline

/// Protocol describing a Jetpack tunnel envelope that wraps a decoded inner value under the `data` key.
private protocol POSDataEnvelope: Decodable {
    associatedtype Inner: Decodable
    var data: Inner { get }
}

/// Tries all known POS response formats in sequence. Throws the most useful error when nothing works.
private func mapPOSResponse<Direct: Decodable, Envelope: POSDataEnvelope>(_ response: Data,
                                                                         decodeDirect: Direct.Type,
                                                                         decodeEnvelope: Envelope.Type) throws -> Direct
where Envelope.Inner == Direct {
    let decoder = JSONDecoder()

    // 1. WC REST error at root (direct REST shape).
    if let wcError = try? decoder.decode(WCRESTError.self, from: response),
       wcError.code != nil {
        throw mapWCError(wcError)
    }

    // 2. WC REST error wrapped in a Jetpack `{"data": {...}}` envelope.
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

    // 5. Nothing matched: surface a descriptive error with a response preview.
    let preview = responsePreview(response)
    DDLogError("<> POS auth mapper could not decode response. Preview: \(preview)")
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

// MARK: - Envelope wrappers for Jetpack tunnel responses

private struct POSPINAuthResultEnvelope: POSDataEnvelope {
    let data: POSPINAuthResult
}

private struct POSApprovalResultEnvelope: POSDataEnvelope {
    let data: POSApprovalResult
}

private struct POSStaffStatusResponseEnvelope: POSDataEnvelope {
    let data: POSStaffStatusResponse
}

private struct POSPINVerifyResultEnvelope: POSDataEnvelope {
    let data: POSPINVerifyResult
}

// MARK: - WC REST Error

/// Envelope for WC REST errors inside Jetpack tunnel `{"data": {...}}` responses.
private struct WCRESTErrorEnvelope: Decodable {
    let data: WCRESTError
}

private struct WCRESTError: Decodable {
    let code: String?
    let message: String?
    let data: WCRESTErrorData?
}

private struct WCRESTErrorData: Decodable {
    let status: Int?
    let retryAfter: Int?

    private enum CodingKeys: String, CodingKey {
        case status
        case retryAfter = "retry_after"
    }
}

private func mapWCError(_ wcError: WCRESTError) -> POSAuthError {
    let code = wcError.code ?? "unknown"
    let message = wcError.message ?? "Unknown error"

    switch code {
    case "woocommerce_pos_invalid_pin":
        return .invalidPIN
    case "woocommerce_pos_rate_limited":
        let retryAfter = wcError.data?.retryAfter ?? 30
        return .rateLimited(retryAfter: retryAfter)
    case "woocommerce_pos_approval_forbidden":
        return .approvalForbidden
    case "woocommerce_pos_invalid_action":
        return .invalidAction
    case "woocommerce_pos_session_expired":
        return .sessionExpired
    default:
        return .unknown(code: code, message: message)
    }
}
