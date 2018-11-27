import Foundation


/// WordPress.com Device Settings
///
public struct DeviceSettings: Decodable {

    /// Dotcom DeviceId
    ///
    public let deviceId: String
}


// MARK: - Nested Types
//
extension DeviceSettings {

    /// Coding Keys
    ///
    private enum CodingKeys: String, CodingKey {
        case deviceId = "ID"
    }
}
