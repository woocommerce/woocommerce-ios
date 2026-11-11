import Foundation
import Testing
@testable import PointOfSale

struct POSPINHashTests {
    @Test func test_matches_when_pin_is_the_hashed_pin_then_returns_true() throws {
        // Given
        let sut = try #require(POSPINHash(pin: "1234", iterations: 10))

        // When / Then
        #expect(sut.matches("1234"))
    }

    @Test func test_matches_when_pin_is_different_then_returns_false() throws {
        // Given
        let sut = try #require(POSPINHash(pin: "1234", iterations: 10))

        // When / Then
        #expect(sut.matches("1235") == false)
    }

    @Test func test_init_when_same_pin_is_hashed_twice_then_uses_different_salts() throws {
        // When
        let first = try #require(POSPINHash(pin: "1234", iterations: 10))
        let second = try #require(POSPINHash(pin: "1234", iterations: 10))

        // Then
        #expect(first.salt != second.salt)
        #expect(first.hash != second.hash)
        #expect(first.salt.count == 16)
        #expect(first.hash.count == 32)
    }

    @Test func test_init_when_using_default_iterations_then_uses_pbkdf2_sha256() throws {
        // When
        let sut = try #require(POSPINHash(pin: "1234"))

        // Then
        #expect(sut.algorithm == "pbkdf2-sha256")
        #expect(sut.iterations == POSPINHash.Constants.defaultIterations)
    }

    @Test func test_matches_when_algorithm_is_unsupported_then_returns_false() throws {
        // Given
        let valid = try #require(POSPINHash(pin: "1234", iterations: 10))
        let sut = POSPINHash(algorithm: "bcrypt", iterations: valid.iterations, salt: valid.salt, hash: valid.hash)

        // When / Then
        #expect(sut.matches("1234") == false)
    }

    @Test func test_matches_when_hash_is_empty_then_returns_false() {
        // Given
        let sut = POSPINHash(algorithm: "pbkdf2-sha256", iterations: 10, salt: Data([1, 2]), hash: Data())

        // When / Then
        #expect(sut.matches("1234") == false)
    }

    @Test(arguments: [0, -1])
    func test_matches_when_iterations_are_not_positive_then_returns_false(iterations: Int) throws {
        // Given
        let valid = try #require(POSPINHash(pin: "1234", iterations: 10))
        let sut = POSPINHash(algorithm: valid.algorithm, iterations: iterations, salt: valid.salt, hash: valid.hash)

        // When / Then
        #expect(sut.matches("1234") == false)
    }

    @Test func test_matches_when_iterations_exceed_the_limit_then_returns_false() throws {
        // Given
        let valid = try #require(POSPINHash(pin: "1234", iterations: 10))
        let sut = POSPINHash(algorithm: valid.algorithm, iterations: 1_000_001, salt: valid.salt, hash: valid.hash)

        // When / Then
        #expect(sut.matches("1234") == false)
    }

    @Test func test_matches_when_hash_is_oversized_then_returns_false() {
        // Given
        let sut = POSPINHash(algorithm: "pbkdf2-sha256", iterations: 10, salt: Data([1]), hash: Data(repeating: 0, count: 65))

        // When / Then
        #expect(sut.matches("1234") == false)
    }
}
