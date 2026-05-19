import Foundation
import struct Networking.QRLoginScanDevice
import UIKit

/// Produces the `device.*` metadata sent on every QR-login `/scan`. Injectable
/// so tests can pin the values without touching `UIDevice` / `Bundle`.
protocol QRLoginDeviceInfoProvider {
    var device: QRLoginScanDevice { get }
}

struct DefaultQRLoginDeviceInfoProvider: QRLoginDeviceInfoProvider {
    var device: QRLoginScanDevice {
        QRLoginScanDevice(
            os: "iOS",
            osVersion: UIDevice.current.systemVersion,
            model: Self.hardwareIdentifier,
            brand: "Apple",
            appVersion: Bundle.main.marketingVersion
        )
    }

    /// e.g. `iPhone17,1`. Falls back to `UIDevice.current.model` (e.g. `iPhone`)
    /// when the sysctl call yields nothing — server applies a per-field cap and
    /// whitelist anyway.
    private static var hardwareIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.compactMap { element -> String? in
            guard let value = element.value as? Int8, value != 0 else { return nil }
            return String(UnicodeScalar(UInt8(value)))
        }.joined()
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }
}
