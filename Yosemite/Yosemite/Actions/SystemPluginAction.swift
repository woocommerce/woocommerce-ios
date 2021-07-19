import Foundation

/// Defines all actions supported by `SystemPluginStore`
///
public enum SystemPluginAction: Action {

    /// Synchronize all system plugins for a site given its ID
    ///
    case synchronizeSystemPlugins(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)
    
    /// Fetch all system plugins for a site given its ID
    ///
    case fetchSystemPlugins(siteID: Int64, onCompletion: ([SystemPlugin]?) -> Void)
}
