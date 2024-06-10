import Foundation
import Storage


// Storage.Site: ReadOnlyConvertible Conformance.
//
extension Storage.Site: ReadOnlyConvertible {

    /// Updates the Storage.Site with the a ReadOnly.
    ///
    public func update(with site: Yosemite.Site) {
        siteID = site.siteID
        name = site.name
        tagline = site.description
        url = site.url
        adminURL = site.adminURL
        loginURL = site.loginURL
        isSiteOwner = site.isSiteOwner
        frameNonce = site.frameNonce
        plan = site.plan
        isAIAssitantFeatureActive = site.isAIAssistantFeatureActive
        isJetpackThePluginInstalled = site.isJetpackThePluginInstalled
        isJetpackConnected = site.isJetpackConnected
        isWooCommerceActive = NSNumber(booleanLiteral: site.isWooCommerceActive)
        isWordPressStore = NSNumber(booleanLiteral: site.isWordPressComStore)
        jetpackConnectionActivePlugins = site.jetpackConnectionActivePlugins
        timezone = site.timezone
        gmtOffset = site.gmtOffset
        visibility = Int64(site.visibility.rawValue)
        canBlaze = site.canBlaze
        isAdmin = site.isAdmin
        wasEcommerceTrial = site.wasEcommerceTrial
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Site {
        return Site(siteID: siteID,
                    name: name ?? "",
                    description: tagline ?? "",
                    url: url ?? "",
                    adminURL: adminURL ?? "",
                    loginURL: loginURL ?? "",
                    isSiteOwner: isSiteOwner,
                    frameNonce: frameNonce ?? "",
                    plan: plan ?? "",
                    isAIAssistantFeatureActive: isAIAssitantFeatureActive,
                    isJetpackThePluginInstalled: isJetpackThePluginInstalled,
                    isJetpackConnected: isJetpackConnected,
                    isWooCommerceActive: isWooCommerceActive?.boolValue ?? false,
                    isWordPressComStore: isWordPressStore?.boolValue ?? false,
                    jetpackConnectionActivePlugins: jetpackConnectionActivePlugins ?? [],
                    timezone: timezone ?? "",
                    gmtOffset: gmtOffset,
                    visibility: SiteVisibility(rawValue: Int(visibility)) ?? .privateSite,
                    canBlaze: canBlaze,
                    isAdmin: isAdmin,
                    wasEcommerceTrial: wasEcommerceTrial)
    }
}
