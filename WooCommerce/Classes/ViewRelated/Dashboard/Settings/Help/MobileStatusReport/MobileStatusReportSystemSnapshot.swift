import Foundation
import UIKit
import UserNotifications
import enum WooFoundationCore.BuildConfiguration
import protocol WooFoundation.ConnectivityObserver
import enum WooFoundation.ConnectivityStatus

/// Everything the Mobile Status Report learns from the device itself, captured in one pass.
///
/// Values are captured already formatted. The connectivity observer and notification center are injected, so
/// their mapping is tested; the rest of `current()` reads live singletons (`Bundle`, `UIDevice`, `UIScreen`,
/// `UIApplication`) at the boundary, and the report itself is tested by building a snapshot literally.
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

    let apnsEnvironment: String
    let authorizationStatus: String
    let alerts: String
    let sounds: String
    let lockScreen: String
    let timeSensitive: String
    let scheduledSummary: String
    let backgroundRefresh: String
    let lowPowerMode: String
}

extension MobileStatusReportSystemSnapshot {

    @MainActor
    static func current(connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver,
                        notificationCenter: UserNotificationsCenterAdapter = UNUserNotificationCenter.current()) async -> Self {
        let notifications = await notificationCenter.notificationSettings()

        return MobileStatusReportSystemSnapshot(version: "\(Bundle.main.marketingVersion) (\(Bundle.main.buildNumber))",
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
                                         expensiveConnection: connectivityObserver.isConnectionMetered
                                            .map(String.init) ?? unknown,
                                         lowDataMode: connectivityObserver.isLowDataModeEnabled
                                            .map(String.init) ?? unknown,
                                         apnsEnvironment: apnsEnvironment,
                                         authorizationStatus: notifications.authorizationStatus.description,
                                         alerts: notifications.alertSetting.description,
                                         sounds: notifications.soundSetting.description,
                                         lockScreen: notifications.lockScreenSetting.description,
                                         timeSensitive: notifications.timeSensitiveSetting.description,
                                         scheduledSummary: notifications.scheduledDeliverySetting.description,
                                         backgroundRefresh: UIApplication.shared.backgroundRefreshStatus.description,
                                         lowPowerMode: String(ProcessInfo.processInfo.isLowPowerModeEnabled))
    }
}

private extension MobileStatusReportSystemSnapshot {

    static let unknown = "unknown"

    static func freeSpace() -> String {
        UIDevice.current.freeDiskSpaceInEnglish ?? unknown
    }

    /// The idiom alongside the size is what actually answers "phone or tablet" when triaging POS.
    @MainActor
    static func screen() -> String {
        let size = UIScreen.main.bounds.size
        return "\(Int(size.width))x\(Int(size.height)) pt (\(UIDevice.current.userInterfaceIdiom.description))"
    }

    /// Read back from the build rather than the entitlement, which has no runtime API. Tokens are not
    /// interchangeable between the two environments, so a mismatch against server logs explains push that works
    /// in one build and not another.
    static var apnsEnvironment: String {
        #if DEBUG
        return "sandbox"
        #else
        return "production"
        #endif
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

private extension UNNotificationSetting {
    var description: String {
        switch self {
        case .notSupported:
            return "not supported"
        case .disabled:
            return "disabled"
        case .enabled:
            return "enabled"
        @unknown default:
            return "unknown"
        }
    }
}

// The ObjC-imported enums carry no case names — `String(describing:)` renders them as
// `UNAuthorizationStatus(rawValue: 2)`, which is exactly what the report must not show.

private extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "notDetermined"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .provisional:
            return "provisional"
        case .ephemeral:
            return "ephemeral"
        @unknown default:
            return "unknown"
        }
    }
}

private extension UIBackgroundRefreshStatus {
    var description: String {
        switch self {
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .available:
            return "available"
        @unknown default:
            return "unknown"
        }
    }
}

private extension UIUserInterfaceIdiom {
    var description: String {
        switch self {
        case .phone:
            return "phone"
        case .pad:
            return "pad"
        case .mac:
            return "mac"
        case .tv:
            return "tv"
        case .carPlay:
            return "carPlay"
        case .vision:
            return "vision"
        case .unspecified:
            return "unspecified"
        @unknown default:
            return "unknown"
        }
    }
}
