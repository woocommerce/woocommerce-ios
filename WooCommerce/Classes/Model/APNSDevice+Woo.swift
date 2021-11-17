import Foundation
import Yosemite


// MARK: - Convenience Methods Initializers
//
extension APNSDevice {

    /// Initializes an APNSDevice Instance, given its deviceToken
    ///
    init(deviceToken: String) {
        let uikitDevice = UIDevice.current

        self.init(token: deviceToken,
                  model: uikitDevice.model,
                  name: uikitDevice.name,
                  iOSVersion: uikitDevice.systemVersion,
                  identifierForVendor: uikitDevice.identifierForVendor?.uuidString)
    }
}
