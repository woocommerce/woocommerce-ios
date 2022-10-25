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
//        plan = site.plan // We're not assigning the plan here because it's not sent on the intial API request.
        isJetpackThePluginInstalled = site.isJetpackThePluginInstalled
        isJetpackConnected = site.isJetpackConnected
        isWooCommerceActive = NSNumber(booleanLiteral: site.isWooCommerceActive)
        isWordPressStore = NSNumber(booleanLiteral: site.isWordPressStore)
        jetpackConnectionActivePlugins = site.jetpackConnectionActivePlugins
        timezone = site.timezone
        gmtOffset = site.gmtOffset
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
                    plan: plan ?? "",
                    isJetpackThePluginInstalled: isJetpackThePluginInstalled,
                    isJetpackConnected: isJetpackConnected,
                    isWooCommerceActive: isWooCommerceActive?.boolValue ?? false,
                    isWordPressStore: isWordPressStore?.boolValue ?? false,
                    jetpackConnectionActivePlugins: jetpackConnectionActivePlugins ?? [],
                    timezone: timezone ?? "",
                    gmtOffset: gmtOffset)
    }
}
