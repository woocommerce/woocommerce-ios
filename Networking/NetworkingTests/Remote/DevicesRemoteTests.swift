import XCTest
@testable import Networking


/// DevicesRemote Unit Tests
///
class DevicesRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that registerDevice parses a "Success" Backend Response.
    ///
    func testRegisterDeviceSuccessfullyParsesDeviceIdentifier() {
        let remote = DevicesRemote(network: network)
        let expectation = self.expectation(description: "Register Device")

        network.simulateResponse(requestUrlSuffix: "devices/new", filename: "device-settings")

        remote.registerDevice(deviceToken: Parameters.deviceToken,
                              deviceModel: Parameters.deviceModel,
                              deviceName: Parameters.deviceName,
                              deviceOSVersion: Parameters.deviceOSVersion,
                              deviceUUID: Parameters.deviceUUID,
                              applicationId: Parameters.applicationId,
                              applicationVersion: Parameters.applicationVersion) { (settings, error) in

                                XCTAssertNil(error)
                                XCTAssertNotNil(settings)
                                XCTAssertEqual(settings?.deviceId, "12345678")
                                expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that registerDevice parses a "Failure" Backend Response.
    ///
    func testRegisterDeviceParsesGeneralFailureResponse() {
        let remote = DevicesRemote(network: network)
        let expectation = self.expectation(description: "Register Device")

        network.simulateResponse(requestUrlSuffix: "devices/new", filename: "generic_error")

        remote.registerDevice(deviceToken: Parameters.deviceToken,
                              deviceModel: Parameters.deviceModel,
                              deviceName: Parameters.deviceName,
                              deviceOSVersion: Parameters.deviceOSVersion,
                              deviceUUID: Parameters.deviceUUID,
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
    func testUnregisterDeviceParsesSuccessResponse() {
        let remote = DevicesRemote(network: network)
        let expectation = self.expectation(description: "Unregister Device")

        let path = String("devices/" + Parameters.deviceId + "/delete")
        network.simulateResponse(requestUrlSuffix: path, filename: "generic_success")

        remote.unregisterDevice(deviceId: Parameters.deviceId) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that unregisterDevice parses a "Failure" Backend Response.
    ///
    func testUnregisterDeviceParsesFailureResponse() {
        let remote = DevicesRemote(network: network)
        let expectation = self.expectation(description: "Unregister Device")

        let path = String("devices/" + Parameters.deviceId + "/delete")
        network.simulateResponse(requestUrlSuffix: path, filename: "generic_error")

        remote.unregisterDevice(deviceId: Parameters.deviceId) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


// MARK: - Sample Device Parameters
//
private enum Parameters {
    static let deviceId = "1234"
    static let deviceToken = "12345678123456781234567812345678"
    static let deviceModel = "iPhone99,1"
    static let deviceName = "iPhone XX"
    static let deviceOSVersion = "iOS 45.1"
    static let deviceUUID = "1234"
    static let applicationId = "9"
    static let applicationVersion = "99"
}
