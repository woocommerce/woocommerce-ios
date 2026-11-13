import Foundation

/// Debug-only overrides for exercising the age-gate consent flow at runtime.
/// Configured from the Debug Panel (Settings → Debug). Always inert in release builds
/// and while unit tests are running.
enum DebugAgeVerificationOverrides {
    /// A simulated developer-declared significant change. When non-nil, the age verification
    /// flow passes it as the `manualChangeIdentifier`, exercising the full consent path
    /// (PermissionKit ask → pending/denied persistence → blocking UI) without an actual
    /// age rating change. Requires a device with a sandbox minor account to go end-to-end.
    static var manualSignificantChangeIdentifier: SignificantChangeIdentifier? {
        #if DEBUG || ALPHA
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
              let id: String = UserDefaults.standard[.debugManualSignificantChangeID],
              id.isEmpty == false else {
            return nil
        }
        return .manual(id: id)
        #else
        return nil
        #endif
    }
}
