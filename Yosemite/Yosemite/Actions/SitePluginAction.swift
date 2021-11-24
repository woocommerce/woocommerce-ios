import Foundation

// Defines all actions supported by `SitePluginStore`
//
public enum SitePluginAction: Action {

    /// Synchronize all plugins for a site given its ID
    case synchronizeSitePlugins(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)

    /// Install the plugin with the specified slug for a site given its ID
    case installSitePlugin(siteID: Int64, slug: String, onCompletion: (Result<Void, Error>) -> Void)

    /// Activate the plugin with the specified name for a site given its ID
    case activateSitePlugin(siteID: Int64, pluginName: String, onCompletion: (Result<Void, Error>) -> Void)

    /// Get details for the plugin with the specified name for a site given its ID
    case getPluginDetails(siteID: Int64, pluginName: String, onCompletion: (Result<SitePlugin, Error>) -> Void)
}
