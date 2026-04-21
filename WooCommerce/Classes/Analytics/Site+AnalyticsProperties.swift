import Foundation
import Yosemite
import protocol WooFoundation.WooAnalyticsEventPropertyType

extension Site {
    /// Analytics properties describing this site. Used by both the default-site enrichment in
    /// `WooAnalytics` (for events about the currently selected site) and by per-target-site event
    /// factories that need to attribute an event to a site other than the selected one.
    var analyticsProperties: [String: WooAnalyticsEventPropertyType] {
        var properties: [String: WooAnalyticsEventPropertyType] = [
            PropertyKeys.blogID: siteID,
            PropertyKeys.siteURL: url,
            PropertyKeys.isWPComStore: isWordPressComStore,
            PropertyKeys.isJetpackInstalled: isJetpackThePluginInstalled,
            PropertyKeys.isJetpackConnected: isJetpackConnected,
            PropertyKeys.isJetpackCPConnected: isJetpackCPConnected,
            PropertyKeys.isCIAB: isCIAB
        ]
        if let gardenPartner {
            properties[PropertyKeys.gardenPartner] = gardenPartner
        }
        return properties
    }

    enum PropertyKeys {
        static let blogID = "blog_id"
        static let siteURL = "site_url"
        static let isWPComStore = "is_wpcom_store"
        static let isJetpackInstalled = "is_jetpack_installed"
        static let isJetpackConnected = "is_jetpack_connected"
        static let isJetpackCPConnected = "is_jetpack_cp_connected"
        static let isCIAB = "is_ciab"
        static let gardenPartner = "garden_partner"
    }
}
