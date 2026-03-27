import protocol WooFoundation.Analytics

extension Analytics {

    /// Track a codegen'd Trackable event through the existing analytics pipeline.
    /// Handles site property enrichment.
    func track(_ event: some Trackable) {
        var properties: [AnyHashable: Any] = event.analyticsProperties.mapValues { $0.description }

        if ServiceLocator.stores.isAuthenticated {
            let site = ServiceLocator.stores.sessionManager.defaultSite
            properties["blog_id"] = site?.siteID
            properties["is_wpcom_store"] = site?.isWordPressComStore
            properties["site_url"] = site?.url
            properties["store_id"] = ServiceLocator.stores.sessionManager.defaultStoreUUID
        }

        track(event.analyticsName, properties: properties.isEmpty ? nil : properties, error: nil)
    }
}
