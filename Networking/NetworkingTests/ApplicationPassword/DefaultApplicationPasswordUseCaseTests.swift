import XCTest
@testable import Networking


/// DefaultApplicationPasswordUseCase Unit Tests
///
final class DefaultApplicationPasswordUseCaseTests: XCTestCase {
    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// URL suffixes
    ///
    private enum URLSuffix {
        static let generateApplicationPassword = "users/me/application-passwords"
    }

    override func setUp() {
        super.setUp()
        network = MockNetwork(useResponseQueue: true)
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    func test_password_is_generated_with_correct_values_upon_success_response() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: URLSuffix.generateApplicationPassword,
                                 filename: "generate-application-password-using-wporg-creds-success")
        let username = "demo"
        let siteAddress = "https://test.com"
        let sut = try DefaultApplicationPasswordUseCase(username: username,
                                                        password: "qeWOhQ5RUV8W",
                                                        siteAddress: siteAddress,
                                                        network: network)

        // When
        let password = try await sut.generateNewPassword()

        // Then
        XCTAssertEqual(password.password.secretValue, "passwordvalue")
        XCTAssertEqual(password.wpOrgUsername, username)
    }
}
