import Foundation


/// WordPress.com Device
///
public struct DotcomDevice: Decodable {

    /// Dotcom DeviceId
    ///
    public let deviceId: String
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
