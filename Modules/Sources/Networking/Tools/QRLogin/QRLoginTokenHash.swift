import CryptoKit
import Foundation

/// Computes the `token_hash` value that the QR-login `/session-status`
/// endpoints expect on every poll.
///
/// The hash is the lowercase-hex SHA-256 over the UTF-8 bytes of the plaintext
/// token, matching PHP `hash('sha256', $token)` (spec §5.1.2 / §5.2.2). Server
/// uses `hash_equals` against the bound session, so any deviation is rejected.
///
/// For the self-hosted protocol the input is the plaintext token from the QR.
/// For the wp.com protocol the input is the **compound** `{64-hex}:{32-hex}`
/// token exactly as it appeared in the QR.
public enum QRLoginTokenHash {

    /// Lowercase-hex SHA-256 of `token`'s UTF-8 bytes.
    public static func make(for token: String) -> String {
        let digest = SHA256.hash(data: Data(token.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
