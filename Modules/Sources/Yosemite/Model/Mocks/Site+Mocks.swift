import Foundation
import struct Networking.Site

public extension Site {
    static func defaultMock() -> Self {
        return Site(
            siteID: 1,
            name: Defaults.Site.name,
            description: "",
            url: Defaults.Site.url,
            adminURL: Defaults.Site.adminURL,
            loginURL: Defaults.Site.loginURL,
            isSiteOwner: false,
            frameNonce: "",
            plan: "",
            isAIAssistantFeatureActive: false,
            isJetpackThePluginInstalled: true,
            isJetpackConnected: true,
            isWooCommerceActive: true,
            isWordPressComStore: false,
            jetpackConnectionActivePlugins: [],
            timezone: "UTC",
            gmtOffset: 0,
            visibility: .publicSite,
            canBlaze: false,
            isAdmin: false,
            wasEcommerceTrial: false,
            hasSSOEnabled: false,
            applicationPasswordAvailable: false,
            isGarden: false,
            gardenName: nil,
            gardenPartner: nil
        )
    }
}
