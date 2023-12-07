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
    func test_device_settings_mapper_correctly_parses_device_identifier() async {
        let settings = try? await mapDotcomDevice(from: sampleDeviceSettings)

        XCTAssertNotNil(settings)
        XCTAssertEqual(settings!.deviceID, "12345678")
    }
}



private extension DotcomDeviceMapperTests {

    /// Returns the DotcomDeviceMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapDotcomDevice(from filename: String) async throws -> DotcomDevice {
        let response = Loader.contentsOf(filename)!
        let mapper = DotcomDeviceMapper()

        return try await mapper.map(response: response)
    }
}
