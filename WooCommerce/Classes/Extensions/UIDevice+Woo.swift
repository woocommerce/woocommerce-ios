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

    /// The device's available disk space in English, e.g. `12.40 GB`, or `nil` when the volume cannot be read.
    ///
    /// English (not `ByteCountFormatter`, which translates its units) because every consumer — support ticket
    /// metadata and the Mobile Status Report — leaves the device to be read by Happiness Engineers.
    ///
    var freeDiskSpaceInEnglish: String? {
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityKey]),
              let capacity = values.volumeAvailableCapacity else {
            return nil
        }
        return Int64(capacity).englishByteCountRepresentable
    }
}
