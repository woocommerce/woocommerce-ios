import Foundation

/// Maps a PIN auth response, handling both:
/// - Jetpack tunnel `{"data": {...}}` envelope
/// - Direct REST `{...}` response
/// - WC REST error `{"code": "...", "message": "...", "data": {"status": N}}`
struct POSPINAuthResultMapper: Mapper {
    typealias Output = POSPINAuthResult

    func map(response: Data) throws -> POSPINAuthResult {
        if let wcError = try? JSONDecoder().decode(WCRESTError.self, from: response),
           wcError.code != nil {
            throw mapWCError(wcError)
        }

        if hasDataEnvelope(in: response) {
            return try JSONDecoder().decode(POSPINAuthResultEnvelope.self, from: response).data
        }
        return try JSONDecoder().decode(POSPINAuthResult.self, from: response)
    }
}

/// Maps an approval response with the same envelope/error handling.
struct POSApprovalResultMapper: Mapper {
    typealias Output = POSApprovalResult

    func map(response: Data) throws -> POSApprovalResult {
        if let wcError = try? JSONDecoder().decode(WCRESTError.self, from: response),
           wcError.code != nil {
            throw mapWCError(wcError)
        }
        if hasDataEnvelope(in: response) {
            return try JSONDecoder().decode(POSApprovalResultEnvelope.self, from: response).data
        }
        return try JSONDecoder().decode(POSApprovalResult.self, from: response)
    }
}

/// Maps a staff status response.
struct POSStaffStatusMapper: Mapper {
    typealias Output = [POSStaffUser]

    func map(response: Data) throws -> [POSStaffUser] {
        if let wcError = try? JSONDecoder().decode(WCRESTError.self, from: response),
           wcError.code != nil {
            throw mapWCError(wcError)
        }
        if hasDataEnvelope(in: response) {
            return try JSONDecoder().decode(POSStaffStatusResponseEnvelope.self, from: response).data.users
        }
        return try JSONDecoder().decode(POSStaffStatusResponse.self, from: response).users
    }
}

// MARK: - Envelope wrappers for Jetpack tunnel responses

private struct POSPINAuthResultEnvelope: Decodable {
    let data: POSPINAuthResult
}

private struct POSApprovalResultEnvelope: Decodable {
    let data: POSApprovalResult
}

private struct POSStaffStatusResponseEnvelope: Decodable {
    let data: POSStaffStatusResponse
}

// MARK: - WC REST Error

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
    case "woocommerce_pos_session_expired":
        return .sessionExpired
    default:
        return .unknown(code: code, message: message)
    }
}
