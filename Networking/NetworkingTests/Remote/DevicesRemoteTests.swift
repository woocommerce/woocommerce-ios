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
    func test_registerDevice_successfully_parses_deviceID() async throws {
        // Given
        let remote = DevicesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "devices/new", filename: "device-settings")

        // When
        let settings = try await remote.registerDevice(device: Parameters.appleDevice,
                                                     applicationId: Parameters.applicationId,
                                                     applicationVersion: Parameters.applicationVersion,
                                                     defaultStoreID: Parameters.defaultStoreID)

        // Then
        XCTAssertEqual(settings.deviceID, "12345678")
    }

    /// Verifies that registerDevice sets the `selected_blog_id` parameter to empty string.
    ///
    func test_registerDevice_sets_selected_blog_id_to_empty_string() async throws {
        // Given
        let remote = DevicesRemote(network: network)

        // When
        _ = try await remote.registerDevice(device: Parameters.appleDevice,
                                          applicationId: Parameters.applicationId,
                                          applicationVersion: Parameters.applicationVersion,
                                          defaultStoreID: Parameters.defaultStoreID)

        // Then
        let queryParameters = try XCTUnwrap(network.queryParameters)
        let expectedParam = "selected_blog_id="
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    /// Verifies that registerDevice parses a "Failure" Backend Response.
    ///
    func test_registerDevice_parses_general_failure_response() async {
        // Given
        let remote = DevicesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "devices/new", filename: "generic_error")

        // When/Then
        do {
            _ = try await remote.registerDevice(device: Parameters.appleDevice,
                                              applicationId: Parameters.applicationId,
                                              applicationVersion: Parameters.applicationVersion,
                                              defaultStoreID: Parameters.defaultStoreID)
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that unregisterDevice parses a "Success" Backend Response.
    ///
    func test_unregisterDevice_parses_success_response() async throws {
        // Given
        let remote = DevicesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "/delete", filename: "generic_success")

        // When/Then
        try await remote.unregisterDevice(deviceId: Parameters.dotcomDeviceID)
    }

    /// Verifies that unregisterDevice parses a "Failure" Backend Response.
    ///
    func test_unregisterDevice_parses_failure_response() async {
        // Given
        let remote = DevicesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "/delete", filename: "generic_error")

        // When/Then
        do {
            try await remote.unregisterDevice(deviceId: Parameters.dotcomDeviceID)
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
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
    static let defaultStoreID: Int64 = 1234
    static let dotcomDeviceID = "1234"
}
