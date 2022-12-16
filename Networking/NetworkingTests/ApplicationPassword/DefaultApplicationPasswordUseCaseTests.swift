import XCTest
@testable import Networking


/// DefaultApplicationPasswordUseCase Unit Tests
///
final class DefaultApplicationPasswordUseCaseTests: XCTestCase {
    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Dummy WPCOM auth token
    ///
    private let credentials = Credentials(authToken: "dummy-token")

    /// Dummy WPCOM auth token
    ///
    private let applicationPasswordURLSuffix = Credentials(authToken: "dummy-token")

    /// URL suffixes
    ///
    private enum URLSuffix {
        static let generateApplicationPassword = "users/me/application-passwords"
        static let usersMe = "users/me"
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
                                 filename: "generate-application-password-using-wpcom-token-success")
        network.simulateResponse(requestUrlSuffix: URLSuffix.usersMe, filename: "user-complete")

        let sut = DefaultApplicationPasswordUseCase(siteID: sampleSiteID,
                                                    networkcredentials: credentials,
                                                    network: network)

        let password = try await sut.generateNewPassword()
        XCTAssertEqual(password.password.secretValue, "passwordvalue")
        XCTAssertEqual(password.wpOrgUsername, "test-username")
    }
}
