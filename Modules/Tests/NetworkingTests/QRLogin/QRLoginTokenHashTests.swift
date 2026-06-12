import Foundation
import Testing
@testable import Networking

struct QRLoginTokenHashTests {

    @Test func make_matches_PHP_hash_sha256_for_known_input() {
        // Given — vector produced by PHP `hash('sha256', 'hello world')`.
        let token = "hello world"

        // When
        let hash = QRLoginTokenHash.make(for: token)

        // Then
        #expect(hash == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9")
    }

    @Test func make_returns_lowercase_hex() {
        // Given
        let token = String(repeating: "A", count: 64)

        // When
        let hash = QRLoginTokenHash.make(for: token)

        // Then
        #expect(hash == hash.lowercased())
        #expect(hash.count == 64) // 32 bytes × 2 hex chars
    }

    @Test func make_treats_empty_string_as_valid_input() {
        // Given — server has its own validation; the hasher just hashes what it
        // is given. SHA-256 of an empty byte sequence is a well-known value.
        let token = ""

        // When
        let hash = QRLoginTokenHash.make(for: token)

        // Then
        #expect(hash == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    @Test func make_hashes_utf8_bytes_so_unicode_input_differs_from_ascii_fallback() {
        // UTF-8 encoding is load-bearing for parity with the PHP server's
        // `hash('sha256', $token)`. A non-ASCII token must produce a hash
        // distinct from its ASCII-only neighbour.
        let unicode = QRLoginTokenHash.make(for: "café")
        let ascii = QRLoginTokenHash.make(for: "cafe")
        #expect(unicode != ascii)
    }

    @Test func make_is_deterministic() {
        // Given
        let token = "deterministic-input"

        // When
        let first = QRLoginTokenHash.make(for: token)
        let second = QRLoginTokenHash.make(for: token)

        // Then
        #expect(first == second)
    }
}
