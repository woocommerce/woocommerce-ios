import Foundation

// Defines all actions supported by `SitePluginStore`
//
public enum SitePluginAction: Action {

    /// Synchronize all plugins for a site given its ID
    case synchronizeSitePlugins(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)
}
