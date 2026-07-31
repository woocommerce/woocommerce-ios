import Foundation
import UIKit
import enum WooFoundationCore.BuildConfiguration
import protocol WooFoundation.ConnectivityObserver
import enum WooFoundation.ConnectivityStatus

/// Everything the Mobile Status Report learns from the device itself, captured in one pass.
///
/// Values are captured already formatted. Everything in `current()` reads a live `Bundle`, `UIDevice`,
/// `UNUserNotificationCenter` or the app-wide connectivity observer and so cannot be exercised by a test at all;
/// keeping the mapping there
/// leaves the untestable part thin and at the boundary, and lets the report be tested by building a snapshot
/// literally.
///
struct MobileStatusReportSystemSnapshot: Equatable {
    let version: String
    let build: String

    let model: String
    let os: String
    let freeSpace: String
    let screen: String
    let deviceLocale: String
    let appLanguage: String

    let networkType: String
    let expensiveConnection: String
    let lowDataMode: String
}

extension MobileStatusReportSystemSnapshot {

    @MainActor
    static func current(connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver) async -> Self {
        MobileStatusReportSystemSnapshot(version: "\(Bundle.main.marketingVersion) (\(Bundle.main.buildNumber))",
                                         build: BuildConfiguration.current.rawValue,
                                         model: UIDevice.current.modelIdentifier,
                                         os: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
                                         freeSpace: freeSpace(),
                                         screen: screen(),
                                         deviceLocale: Locale.current.identifier(.bcp47),
                                         appLanguage: Bundle.main.preferredLocalizations.first ?? unknown,
                                         networkType: connectivityObserver.currentStatus.description,
                                         // From the observer's app-lifetime path monitor — the report must not
                                         // spin up its own and wait on a first update.
                                         expensiveConnection: connectivityObserver.isCurrentPathExpensive
                                            .map(String.init) ?? unknown,
                                         lowDataMode: connectivityObserver.isCurrentPathConstrained
                                            .map(String.init) ?? unknown)
    }
}

private extension MobileStatusReportSystemSnapshot {

    static let unknown = "unknown"

    /// Not `ByteCountFormatter`, which translates its units: the report leaves the device and is read by
    /// Happiness Engineers rather than by the merchant.
    static func freeSpace() -> String {
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityKey]),
              let capacity = values.volumeAvailableCapacity else {
            return unknown
        }
        return Int64(capacity).englishByteCountRepresentable
    }

    /// The idiom alongside the size is what actually answers "phone or tablet" when triaging POS.
    @MainActor
    static func screen() -> String {
        let size = UIScreen.main.bounds.size
        return "\(Int(size.width))x\(Int(size.height)) pt (\(String(describing: UIDevice.current.userInterfaceIdiom)))"
    }

}

private extension ConnectivityStatus {
    var description: String {
        switch self {
        case .reachable(.ethernetOrWiFi):
            return "WiFi or Ethernet"
        case .reachable(.cellular):
            return "Cellular"
        case .reachable(.other):
            return "Other"
        case .notReachable:
            return "Not reachable"
        case .unknown:
            return "Unknown"
        }
    }
}

