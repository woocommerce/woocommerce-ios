import XCTest
@testable import Networking

final class ApplicationPasswordEncoderTests: XCTestCase {

    func test_nil_password_envelope_returns_nil_password() {
        let encoder = ApplicationPasswordEncoder(passwordEnvelope: nil)
        XCTAssertNil(encoder.encodedPassword())
    }

    func test_sample_password_envelope_returns_encoded_password() {
        // Given
        let envelope = ApplicationPassword(wpOrgUsername: "This", password: .init("is-a-test"), uuid: "")

        // When
        let encoder = ApplicationPasswordEncoder(passwordEnvelope: envelope)

        // Then
        let expected = "VGhpczppcy1hLXRlc3Q=" /// `This:is-a-test` encoded with https://www.base64encode.org/
        XCTAssertEqual(encoder.encodedPassword(), expected)
    }
}
