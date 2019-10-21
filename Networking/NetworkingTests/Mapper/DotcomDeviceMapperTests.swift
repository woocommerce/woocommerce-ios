import XCTest

@testable import Networking

/// DotcomDeviceMapper: Unit Tests
///
class DotcomDeviceMapperTests: XCTestCase {

    /// DeviceSettings Sample Document
    ///
    private let sampleDeviceSettings = "device-settings"


    /// Verifies that DotcomDeviceMapper correctly parses the DeviceSettings Entity
    ///
    func testDeviceSettingsMapperCorrectlyParsesDeviceIdentifier() {
        let settings = try? mapDotcomDevice(from: sampleDeviceSettings)

        XCTAssertNotNil(settings)
        XCTAssertEqual(settings!.deviceID, "12345678")
    }
}


extension DotcomDeviceMapperTests {

    /// Returns the DotcomDeviceMapper output upon receiving `filename` (Data Encoded)
    ///
    fileprivate func mapDotcomDevice(from filename: String) throws -> DotcomDevice {
        let response = Loader.contentsOf(filename)!
        let mapper = DotcomDeviceMapper()

        return try mapper.map(response: response)
    }
}
