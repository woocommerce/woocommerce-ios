import XCTest
@testable import Networking


/// DevicesRemote Unit Tests
///
class DevicesRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

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

    /// Verifies that registerDevice parses a "Failure" Backend Response.
    ///
    func testRegisterDeviceParsesGeneralFailureResponse() {
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
    func testUnregisterDeviceParsesSuccessResponse() {
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
    func testUnregisterDeviceParsesFailureResponse() {
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
