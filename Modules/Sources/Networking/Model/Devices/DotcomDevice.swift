import Foundation


/// WordPress.com Device
///
public struct DotcomDevice: Decodable {

    /// Dotcom DeviceId
    ///
    public let deviceID: String


    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let deviceId = container.failsafeDecodeIfPresent(stringForKey: .deviceID) else {
            throw DotcomDeviceParseError.missingDeviceID
        }

        self.deviceID = deviceId
    }
}


// MARK: - Nested Types
//
extension DotcomDevice {

    /// Coding Keys
    ///
    private enum CodingKeys: String, CodingKey {
        case deviceID = "ID"
    }
}


/// Parsing Errors
///
enum DotcomDeviceParseError: Error {
    case missingDeviceID
}
