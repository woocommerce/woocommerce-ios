import Foundation

/// Defines all actions supported by `SystemPluginStore`
///
public enum SystemStatusAction: Action {

    /// Synchronize all system plugins for a site given its ID
    ///
    case synchronizeSystemPlugins(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)

    /// Fetch an specific systemPlugin by siteID and name
    ///
    case fetchSystemPlugin(siteID: Int64, systemPluginName: String, onCompletion: (SystemPlugin?) -> Void)

    /// Fetch system status report for a site given its ID
    ///
    case fetchSystemStatusReport(siteID: Int64, onCompletion: (Result<SystemStatus, Error>) -> Void)
}
