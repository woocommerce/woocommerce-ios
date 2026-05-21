import Foundation

/// Helpers for turning a QR-login HTTP response body into a typed value.
///
/// QR-login Remotes go through `URLSession` directly (see `SelfHostedQRLoginRemote`),
/// so they own JSON decoding rather than delegating to a `Mapper`. Both helpers
/// are protocol-agnostic — they handle self-hosted and wp.com bodies the same
/// way; the endpoint-specific shapes live in the `Decodable` response structs.
enum QRLoginResponseBody {

    /// Decodes `data` as `T`, translating *any* decoding failure — malformed
    /// JSON, missing keys, blank required fields — into
    /// `QRLoginNetworkError.malformed`. Spec §5.1.1 / §5.2.1: "all fields are
    /// required; if any is missing or blank, the response is treated as
    /// malformed."
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw QRLoginNetworkError.malformed
        }
    }

    /// Best-effort extraction of an error `code` field from a non-2xx response
    /// body. WordPress REST endpoints return
    /// `{ "code": "...", "message": "...", "data": { "status": <int> } }`.
    /// Returns `nil` if the body isn't JSON-decodable or carries no `code`.
    static func errorCode(in data: Data) -> String? {
        struct ErrorEnvelope: Decodable {
            let code: String?
        }
        return (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.code
    }
}
