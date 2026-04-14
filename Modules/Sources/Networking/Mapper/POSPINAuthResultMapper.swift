import Foundation

/// Maps a PIN auth response, handling both:
/// - Jetpack tunnel `{"data": {...}}` envelope
/// - Direct REST `{...}` response
/// - WC REST error `{"code": "...", "message": "...", "data": {"status": N}}`
struct POSPINAuthResultMapper: Mapper {
    typealias Output = POSPINAuthResult

    func map(response: Data) throws -> POSPINAuthResult {
        // Check for WC REST error at root level (direct REST)
        if let wcError = try? JSONDecoder().decode(WCRESTError.self, from: response),
           wcError.code != nil {
            throw mapWCError(wcError)
        }

        if hasDataEnvelope(in: response) {
            // Check for WC REST error inside the data envelope (Jetpack tunnel)
            if let envelope = try? JSONDecoder().decode(WCRESTErrorEnvelope.self, from: response),
               envelope.data.code != nil {
                throw mapWCError(envelope.data)
            }
            return try JSONDecoder().decode(POSPINAuthResultEnvelope.self, from: response).data
        }
        return try JSONDecoder().decode(POSPINAuthResult.self, from: response)
    }
}

/// Maps an approval response with the same envelope/error handling.
struct POSApprovalResultMapper: Mapper {
    typealias Output = POSApprovalResult

    func map(response: Data) throws -> POSApprovalResult {
        // Check for WC REST error at root level (direct REST)
        if let wcError = try? JSONDecoder().decode(WCRESTError.self, from: response),
           wcError.code != nil {
            throw mapWCError(wcError)
        }
        if hasDataEnvelope(in: response) {
            // Check for WC REST error inside the data envelope (Jetpack tunnel)
            if let envelope = try? JSONDecoder().decode(WCRESTErrorEnvelope.self, from: response),
               envelope.data.code != nil {
                throw mapWCError(envelope.data)
            }
            return try JSONDecoder().decode(POSApprovalResultEnvelope.self, from: response).data
        }
        return try JSONDecoder().decode(POSApprovalResult.self, from: response)
    }
}

/// Maps a staff status response.
struct POSStaffStatusMapper: Mapper {
    typealias Output = [POSStaffUser]

    func map(response: Data) throws -> [POSStaffUser] {
        // Check for WC REST error at root level (direct REST)
        if let wcError = try? JSONDecoder().decode(WCRESTError.self, from: response),
           wcError.code != nil {
            throw mapWCError(wcError)
        }
        if hasDataEnvelope(in: response) {
            // Check for WC REST error inside the data envelope (Jetpack tunnel)
            if let envelope = try? JSONDecoder().decode(WCRESTErrorEnvelope.self, from: response),
               envelope.data.code != nil {
                throw mapWCError(envelope.data)
            }
            return try JSONDecoder().decode(POSStaffStatusResponseEnvelope.self, from: response).data.users
        }
        return try JSONDecoder().decode(POSStaffStatusResponse.self, from: response).users
    }
}

/// Maps a PIN verify response with the same envelope/error handling.
struct POSPINVerifyResultMapper: Mapper {
    typealias Output = POSPINVerifyResult

    func map(response: Data) throws -> POSPINVerifyResult {
        // Check for WC REST error at root level (direct REST)
        if let wcError = try? JSONDecoder().decode(WCRESTError.self, from: response),
           wcError.code != nil {
            throw mapWCError(wcError)
        }
        if hasDataEnvelope(in: response) {
            // Check for WC REST error inside the data envelope (Jetpack tunnel)
            if let envelope = try? JSONDecoder().decode(WCRESTErrorEnvelope.self, from: response),
               envelope.data.code != nil {
                throw mapWCError(envelope.data)
            }
            return try JSONDecoder().decode(POSPINVerifyResultEnvelope.self, from: response).data
        }
        return try JSONDecoder().decode(POSPINVerifyResult.self, from: response)
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

private struct POSPINVerifyResultEnvelope: Decodable {
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
