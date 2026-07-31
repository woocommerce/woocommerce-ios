import Foundation
import enum WooFoundationCore.BuildConfiguration

/// Everything the Mobile Status Report learns from the device itself, captured in one pass.
///
/// Values are captured already formatted. Everything in `current()` reads a live `Bundle`, `UIDevice`,
/// `UNUserNotificationCenter` or `NWPath` and so cannot be exercised by a test at all; keeping the mapping there
/// leaves the untestable part thin and at the boundary, and lets the report be tested by building a snapshot
/// literally.
///
struct MobileStatusReportSystemSnapshot: Equatable {
    let version: String
    let build: String
}

extension MobileStatusReportSystemSnapshot {

    @MainActor
    static func current() async -> Self {
        MobileStatusReportSystemSnapshot(version: "\(Bundle.main.marketingVersion) (\(Bundle.main.buildNumber))",
                                         build: BuildConfiguration.current.rawValue)
    }
}
