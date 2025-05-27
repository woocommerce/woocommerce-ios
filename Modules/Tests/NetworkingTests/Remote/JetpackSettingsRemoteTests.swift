import XCTest
import TestKit
@testable import Networking

final class JetpackSettingsRemoteTests: XCTestCase {
    private var network: MockNetwork!
    private var remote: JetpackSettingsRemote!

    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        remote = JetpackSettingsRemote(network: network)
    }

    func test_enableJetpackModule_correctly_returns_on_success() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "jetpack/v4/settings", filename: "jetpack-settings-success")

        // When
        try await remote.enableJetpackModule(for: sampleSiteID, moduleSlug: "stats")
    }

    func test_enableJetpackModule_returns_DotcomError_failure_on_invalid_option_error() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "jetpack/v4/settings", filename: "jetpack-settings-invalid-module")

        await assertThrowsError({
            // When
            try await remote.enableJetpackModule(for: sampleSiteID, moduleSlug: "invalidmodule")
        }, errorAssert: { error in
            (error as? DotcomError) == .unknown(code: "some_updated", message: "Invalid option: invalidmodule.")
        })
    }

    func test_enableJetpackModule_properly_relays_network_errors() async throws {
        // Given
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "jetpack/v4/settings", error: expectedError)

        // When & Then
        await assertThrowsError({
            try await remote.enableJetpackModule(for: sampleSiteID, moduleSlug: "stats")
        }, errorAssert: { ($0 as? NetworkError) == expectedError })
    }
}
