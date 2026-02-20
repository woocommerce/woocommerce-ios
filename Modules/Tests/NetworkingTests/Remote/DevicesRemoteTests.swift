import XCTest
@testable import Networking
@testable import NetworkingCore


/// DevicesRemote Unit Tests
///
final class DevicesRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private let network = MockNetwork()

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }


    /// Verifies that registerDevice parses a "Success" Backend Response.
    ///
    func test_registerDevice_successfully_parses_deviceID() {
        let remote = DevicesRemote(network: network)
        let expectation = self.expectation(description: "Register Device")

        network.simulateResponse(requestUrlSuffix: "devices/new", filename: "device-settings")

        remote.registerDevice(device: Parameters.appleDevice,
                              applicationId: Parameters.applicationId,
                              applicationVersion: Parameters.applicationVersion) { (settings, error) in

            XCTAssertNil(error)
            XCTAssertNotNil(settings)
            XCTAssertEqual(settings?.deviceID, "12345678")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that registerDevice parses a "Failure" Backend Response.
    ///
    func test_registerDevice_parses_general_failure_response() {
        let remote = DevicesRemote(network: network)
        let expectation = self.expectation(description: "Register Device")

        network.simulateResponse(requestUrlSuffix: "devices/new", filename: "generic_error")

        remote.registerDevice(device: Parameters.appleDevice,
                              applicationId: Parameters.applicationId,
                              applicationVersion: Parameters.applicationVersion) { (settings, error) in

            XCTAssertNotNil(error)
            XCTAssertNil(settings)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that unregisterDevice parses a "Success" Backend Response.
    ///
    func test_unregisterDevice_parses_success_response() {
        let remote = DevicesRemote(network: network)
        let expectation = self.expectation(description: "Unregister Device")

        network.simulateResponse(requestUrlSuffix: "/delete", filename: "generic_success")

        remote.unregisterDevice(deviceId: Parameters.dotcomDeviceID) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that unregisterDevice parses a "Failure" Backend Response.
    ///
    func test_unregisterDevice_parses_failure_response() {
        let remote = DevicesRemote(network: network)
        let expectation = self.expectation(description: "Unregister Device")

        network.simulateResponse(requestUrlSuffix: "/delete", filename: "generic_error")

        remote.unregisterDevice(deviceId: Parameters.dotcomDeviceID) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that registerForSelfDrivenPushNotifications successfully parses the token ID.
    ///
    func test_registerForSelfDrivenPushNotifications_successfully_parses_tokenID() async throws {
        let remote = DevicesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc-push-notifications/push-tokens", filename: "self-driven-pn-registration")

        let tokenID = try await remote.registerForSelfDrivenPushNotifications(
            siteID: Parameters.siteID,
            device: Parameters.appleDevice,
            applicationID: Parameters.applicationId,
            deviceLocale: Parameters.deviceLocale,
            appVersion: Parameters.applicationVersion
        )

        XCTAssertEqual(tokenID, 123)
    }

    /// Verifies that registerForSelfDrivenPushNotifications parses a "Failure" Backend Response.
    ///
    func test_registerForSelfDrivenPushNotifications_parses_failure_response() async {
        let remote = DevicesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc-push-notifications/push-tokens", filename: "generic_error")

        do {
            _ = try await remote.registerForSelfDrivenPushNotifications(
                siteID: Parameters.siteID,
                device: Parameters.appleDevice,
                applicationID: Parameters.applicationId,
                deviceLocale: Parameters.deviceLocale,
                appVersion: Parameters.applicationVersion
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    /// Verifies that unregisterFromSelfDrivenPushNotifications parses a "Success" Backend Response.
    ///
    func test_unregisterFromSelfDrivenPushNotifications_parses_success_response() async throws {
        let remote = DevicesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc-push-notifications/push-tokens/\(Parameters.tokenID)", filename: "generic_success")

        try await remote.unregisterFromSelfDrivenPushNotifications(
            siteID: Parameters.siteID,
            tokenID: Parameters.tokenID
        )
        // If no error is thrown, the test passes
    }

    /// Verifies that unregisterFromSelfDrivenPushNotifications parses a "Failure" Backend Response.
    ///
    func test_unregisterFromSelfDrivenPushNotifications_parses_failure_response() async {
        let remote = DevicesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "wc-push-notifications/push-tokens/\(Parameters.tokenID)", filename: "generic_error")

        do {
            try await remote.unregisterFromSelfDrivenPushNotifications(
                siteID: Parameters.siteID,
                tokenID: Parameters.tokenID
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}


// MARK: - Sample Device Parameters
//
private enum Parameters {
    static let appleDevice = APNSDevice(token: "12345678123456781234567812345678",
                                        model: "iPhone99,1",
                                        name: "iPhone XX",
                                        iOSVersion: "iOS 45.1",
                                        identifierForVendor: "1234")
    static let applicationId = "9"
    static let applicationVersion = "99"
    static let dotcomDeviceID = "1234"
    static let siteID: Int64 = 123456
    static let tokenID: Int64 = 123
    static let deviceLocale = "en_US"
}
