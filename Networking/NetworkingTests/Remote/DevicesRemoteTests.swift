import XCTest
@testable import Networking


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
                              applicationVersion: Parameters.applicationVersion,
                              defaultStoreID: Parameters.defaultStoreID) { (settings, error) in

            XCTAssertNil(error)
            XCTAssertNotNil(settings)
            XCTAssertEqual(settings?.deviceID, "12345678")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that registerDevice sets the `selected_blog_id` parameter to empty string.
    ///
    func test_registerDevice_sets_selected_blog_id_to_empty_string() throws {
        // Given
        let remote = DevicesRemote(network: network)

        // When
        remote.registerDevice(device: Parameters.appleDevice,
                              applicationId: Parameters.applicationId,
                              applicationVersion: Parameters.applicationVersion,
                              defaultStoreID: Parameters.defaultStoreID) { (_, _) in }

        // Then
        let queryParameters = try XCTUnwrap(network.queryParameters)
        let expectedParam = "selected_blog_id="
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    /// Verifies that registerDevice parses a "Failure" Backend Response.
    ///
    func test_registerDevice_parses_general_failure_response() {
        let remote = DevicesRemote(network: network)
        let expectation = self.expectation(description: "Register Device")

        network.simulateResponse(requestUrlSuffix: "devices/new", filename: "generic_error")

        remote.registerDevice(device: Parameters.appleDevice,
                              applicationId: Parameters.applicationId,
                              applicationVersion: Parameters.applicationVersion,
                              defaultStoreID: Parameters.defaultStoreID) { (settings, error) in

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
    static let defaultStoreID: Int64 = 1234
    static let dotcomDeviceID = "1234"
}
