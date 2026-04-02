import EventHorizonSDK
import protocol WooFoundation.Analytics

extension Analytics {

    /// Track a codegen'd Trackable event through the existing analytics pipeline.
    /// Site property enrichment is handled by `appendSiteProperties(to:)` in WooAnalytics.swift.
    func track(_ event: some Trackable) {
        let properties = event.analyticsProperties as [AnyHashable: Any]
        let enrichedProperties = appendSiteProperties(to: properties)
        track(event.analyticsName, properties: enrichedProperties, error: nil)
    }
}
