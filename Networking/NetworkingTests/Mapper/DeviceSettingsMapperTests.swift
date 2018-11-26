import XCTest
@testable import Networking


/// DeviceSettingsMapper: Unit Tests
///
class DeviceSettingsMapperTests: XCTestCase {

    /// DeviceSettings Sample Document
    ///
    private let sampleDeviceSettings = "device-settings"


    /// Verifies that DeviceSettingsMapper correctly parses the DeviceSettings Entity
    ///
    func testDeviceSettingsMapperCorrectlyParsesDeviceIdentifier() {
        let settings = try? mapSettings(from: sampleDeviceSettings)

        XCTAssertNotNil(settings)
        XCTAssertEqual(settings!.deviceId, "12345678")
    }
}



private extension DeviceSettingsMapperTests {

    /// Returns the DeviceSettingsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapSettings(from filename: String) throws -> DeviceSettings {
        let response = Loader.contentsOf(filename)!
        let mapper = DeviceSettingsMapper()

        return try mapper.map(response: response)
    }
}
