import Networking
import UIKit

extension UIDevice {

    var deviceModelIdentifierInfo: DeviceModelIdentifierInfo {
        DeviceModelIdentifierInfo(
            model: model,
            identifierForVendor: identifierForVendor?.uuidString ?? ""
        )
    }
}
