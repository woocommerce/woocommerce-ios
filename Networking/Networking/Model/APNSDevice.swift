import Foundation


/// Represents an Apple Push Notifications Service Device.
///
public struct APNSDevice {

    /// Push Notifications Token.
    ///
    let token: String

    /// Device Family.
    ///
    let family: String = "apple"

    /// Device Model.
    ///
    let model: String

    /// Device Name.
    ///
    let name: String

    /// OS Version we're currently running.
    ///
    let iOSVersion: String

    /// Device's UUID.
    ///
    let identifierForVendor: String?
}
