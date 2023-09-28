/// Mapper: SitePlugin
///
struct SitePluginMapper: Mapper {

    /// Site Identifier associated to the plugin that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID in the plugin endpoint.
    ///
    private let siteID: Int64

    /// Initialized a mapper to serialize site plugins.
    /// - Parameters:
    ///   - siteID: Identifier for the site. Only required in authenticated state.
    ///
    init(siteID: Int64 = WooConstants.placeholderSiteID) {
        self.siteID = siteID
    }

    /// (Attempts) to convert a dictionary into SitePlugin.
    ///
    func map(response: Data) throws -> SitePlugin {
        try extract(from: response, usingJSONDecoderSiteID: siteID)
    }
}
