import Foundation

/// Defines all actions supported by `SystemPluginStore`
///
public enum SystemStatusAction: Action {

    /// Synchronize store information from the system status for a site given its ID.
    ///
    case synchronizeSystemInformation(siteID: Int64, onCompletion: (Result<SystemInformation, Error>) -> Void)

    /// Fetch a specific systemPlugin by path.
    ///
    case fetchSystemPluginWithPath(siteID: Int64, pluginPath: String, onCompletion: (SystemPlugin?) -> Void)

    /// Fetch system status report for a site given its ID
    ///
    case fetchSystemStatusReport(siteID: Int64, onCompletion: (Result<SystemStatusReport, Error>) -> Void)
}
