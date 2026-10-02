import Foundation
import UIKit
import Yosemite

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
            // The web shows `model` to the merchant (and uses it in the sign-in email and the
            // Application Password name), so send the generic `iPhone` / `iPad` rather than the
            // hardware identifier (`iPhone14,2`). iOS has no public API for the marketing name.
            model: UIDevice.current.model,
            brand: "Apple",
            appVersion: Bundle.main.marketingVersion
        )
    }
}
