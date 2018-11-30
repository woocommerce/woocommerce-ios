import Foundation


/// WordPress.com Device
///
public struct DotcomDevice: Decodable {

    /// Dotcom DeviceId
    ///
    public let deviceId: String


    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let deviceId = container.failsafeDecodeIfPresent(stringForKey: .deviceId) else {
            throw DotcomDeviceParseError.missingDeviceID
        }

        self.deviceId = deviceId
    }
}


// MARK: - Nested Types
//
extension DotcomDevice {

    /// Coding Keys
    ///
    private enum CodingKeys: String, CodingKey {
        case deviceId = "ID"
    }
}


/// Parsing Errors
///
enum DotcomDeviceParseError: Error {
    case missingDeviceID
}
