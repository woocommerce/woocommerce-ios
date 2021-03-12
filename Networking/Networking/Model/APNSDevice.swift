import Foundation


/// Represents an Apple Push Notifications Service Device.
///
public struct APNSDevice: GeneratedFakeable {

    /// Push Notifications Token.
    ///
    public let token: String

    /// Device Family.
    ///
    public let family: String = "apple"

    /// Device Model.
    ///
    public let model: String

    /// Device Name.
    ///
    public let name: String

    /// OS Version we're currently running.
    ///
    public let iOSVersion: String

    /// Device's UUID.
    ///
    public let identifierForVendor: String?


    /// Designated initializer.
    ///
    public init(token: String, model: String, name: String, iOSVersion: String, identifierForVendor: String?) {
        self.token = token
        self.model = model
        self.name = name
        self.iOSVersion = iOSVersion
        self.identifierForVendor = identifierForVendor
    }
}
