import Foundation

extension WooAnalyticsEvent {
    enum GoogleAds {
        enum Source: String {
            case moreMenu = "more_menu"
            case myStore = "my_store"
            case analyticsHub = "analytics_hub"
        }

        enum FlowType: String {
            case campaignCreation = "creation"
            case dashboard = "dashboard"
        }

        private enum Keys: String {
            case hasCampaigns = "has_campaigns"
            case source
            case type
        }

        /// When the Google for Woo entry point is shown to the user.
        static func entryPointDisplayed(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .googleAdsEntryPointDisplayed,
                              properties: [Keys.source.rawValue: source.rawValue])
        }

        /// When the Google for Woo entry point is tapped by the user and opens to campaign creation.
        static func entryPointTapped(source: Source, type: FlowType, hasCampaigns: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .googleAdsEntryPointTapped,
                              properties: [Keys.source.rawValue: source.rawValue,
                                           Keys.type.rawValue: type.rawValue,
                                           Keys.hasCampaigns.rawValue: hasCampaigns])
        }

        /// When the Google for Woo web view is first loaded.
        static func flowStarted(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .googleAdsFlowStarted,
                              properties: [Keys.source.rawValue: source.rawValue])
        }

        /// When the Google for Woo web view is dismissed without completing the flow.
        static func flowCanceled(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .googleAdsFlowCanceled,
                              properties: [Keys.source.rawValue: source.rawValue])
        }

        /// When the Google for Woo web view returns an error.
        static func flowError(source: Source, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .googleAdsFlowError,
                              properties: [Keys.source.rawValue: source.rawValue],
                              error: error)
        }

        /// When the Google for Woo web view is automatically dismissed after completing the creation
        static func campaignCreationSuccess(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .googleAdsCampaignCreationSuccess,
                              properties: [Keys.source.rawValue: source.rawValue])
        }
    }
}
