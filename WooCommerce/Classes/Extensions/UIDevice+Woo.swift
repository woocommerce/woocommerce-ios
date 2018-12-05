import Foundation
import UIKit


/// UIDevice: Woo Methods
///
extension UIDevice {

    /// Returns the Model Identifier of the device. For example, `iPhone5,3`, `iPad3,1`, `iPod5,1`
    ///
    var modelIdentifier: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)

        return String(cString: machine)
    }
}
