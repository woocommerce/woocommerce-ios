import Foundation

/// Maps a PIN auth response, handling both success and WC REST error formats.
/// Required because Jetpack tunnel doesn't relay proper HTTP status codes,
/// so error responses (422, 403) arrive as HTTP 200 with error JSON body.
struct POSPINAuthResultMapper: Mapper {
    typealias Output = POSPINAuthResult

    func map(response: Data) throws -> POSPINAuthResult {
        // First try to decode as a WC REST error
        if let wcError = try? JSONDecoder().decode(WCRESTError.self, from: response),
           wcError.code != nil {
            throw mapWCError(wcError)
        }

        // Then decode as the success model
        return try JSONDecoder().decode(POSPINAuthResult.self, from: response)
    }
}

/// Maps an approval response with the same error-first pattern.
struct POSApprovalResultMapper: Mapper {
    typealias Output = POSApprovalResult

    func map(response: Data) throws -> POSApprovalResult {
        if let wcError = try? JSONDecoder().decode(WCRESTError.self, from: response),
           wcError.code != nil {
            throw mapWCError(wcError)
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
        let container = try JSONDecoder().decode(POSStaffStatusResponse.self, from: response)
        return container.users
    }
}

/// Minimal WC REST error structure for pre-decode error checking.
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

/// Maps a WC REST error response to a typed POSAuthError.
/// Defined at file scope so all mappers can use it.
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
