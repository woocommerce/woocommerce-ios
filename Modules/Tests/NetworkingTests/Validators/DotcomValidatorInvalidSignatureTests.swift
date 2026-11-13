import Foundation
import Testing
@testable import NetworkingCore

/// Covers how the invalid signature error is recognised. The store rejects our requests under an
/// identifier that reaches us under either `error` or `code` depending on which layer answers, so both
/// shapes are pinned here — as is the fact that reading `code` stays limited to this one identifier.
///
struct DotcomValidatorInvalidSignatureTests {

    @Test func test_validate_when_the_body_names_the_error_then_it_throws_invalidSignature() throws {
        // Given
        let data = try #require(#"{"error":"rest_invalid_signature","message":"The request is not signed correctly."}"#.data(using: .utf8))

        // When
        let error = capturedError(validating: data)

        // Then
        #expect(error as? DotcomError == .invalidSignature())
    }

    @Test func test_validate_when_the_body_names_the_code_then_it_throws_invalidSignature() throws {
        // Given
        let json = #"{"code":"rest_invalid_signature","message":"The request is not signed correctly.","data":{"status":400}}"#
        let data = try #require(json.data(using: .utf8))

        // When
        let error = capturedError(validating: data)

        // Then
        #expect(error as? DotcomError == .invalidSignature())
    }

    @Test func test_validate_when_the_body_names_the_code_then_it_keeps_the_error_data() throws {
        // Given
        let json = #"{"code":"rest_invalid_signature","message":"The request is not signed correctly.","data":{"status":400}}"#
        let data = try #require(json.data(using: .utf8))

        // When
        let error = capturedError(validating: data)

        // Then
        guard case let .invalidSignature(errorData) = try #require(error as? DotcomError) else {
            Issue.record("Expected DotcomError.invalidSignature")
            return
        }
        #expect(errorData?["status"]?.value as? Int == 400)
    }

    @Test func test_validate_when_the_body_names_both_an_error_and_a_code_then_the_error_wins() throws {
        // Given
        let json = #"{"error":"unknown_blog","code":"rest_invalid_signature","message":"Unknown blog."}"#
        let data = try #require(json.data(using: .utf8))

        // When
        let error = capturedError(validating: data)

        // Then
        #expect(error as? DotcomError == .unknownBlog())
    }

    @Test func test_validate_when_the_body_names_another_code_then_it_does_not_throw() throws {
        // Given
        let json = #"{"code":"rest_no_route","message":"No route was found matching the URL.","data":{"status":404}}"#
        let data = try #require(json.data(using: .utf8))

        // When, Then
        #expect(throws: Never.self) {
            try DotcomValidator().validate(data: data)
        }
    }

    @Test func test_validate_when_the_body_is_not_an_error_then_it_does_not_throw() throws {
        // Given
        let data = try #require(#"{"code":200,"body":{"id":1}}"#.data(using: .utf8))

        // When, Then
        #expect(throws: Never.self) {
            try DotcomValidator().validate(data: data)
        }
    }
}

private extension DotcomValidatorInvalidSignatureTests {
    func capturedError(validating data: Data) -> Error? {
        do {
            try DotcomValidator().validate(data: data)
            return nil
        } catch {
            return error
        }
    }
}
