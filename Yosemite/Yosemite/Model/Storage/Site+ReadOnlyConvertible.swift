import Foundation
import Storage


// Storage.Site: ReadOnlyConvertible Conformance.
//
extension Storage.Site: ReadOnlyConvertible {

    /// Updates the Storage.Site with the a ReadOnly.
    ///
    public func update(with site: Yosemite.Site) {
        siteID = Int64(site.siteID)
        name = site.name
        tagline = site.description
        url = site.url
        plan = site.plan
        isJetpackInstalled = NSNumber(booleanLiteral: site.isJetpackInstalled)
        isWooCommerceActive = NSNumber(booleanLiteral: site.isWooCommerceActive)
        isWordPressStore = NSNumber(booleanLiteral: site.isWordPressStore)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Site {
        return Site(siteID: Int(siteID),
                    name: name ?? "",
                    description: tagline ?? "",
                    url: url ?? "",
                    plan: plan ?? "",
                    isJetpackInstalled: isJetpackInstalled?.boolValue ?? false,
                    isWooCommerceActive: isWooCommerceActive?.boolValue ?? false,
                    isWordPressStore: isWordPressStore?.boolValue ?? false)
    }
}
