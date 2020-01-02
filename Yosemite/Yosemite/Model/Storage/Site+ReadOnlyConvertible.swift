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
//        plan = site.plan // We're not assigning the plan here because it's not sent on the intial API request.
        isWooCommerceActive = NSNumber(booleanLiteral: site.isWooCommerceActive)
        isWordPressStore = NSNumber(booleanLiteral: site.isWordPressStore)
        timezone = site.timezone
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Site {
        return Site(siteID: siteID,
                    name: name ?? "",
                    description: tagline ?? "",
                    url: url ?? "",
                    plan: plan ?? "",
                    isWooCommerceActive: isWooCommerceActive?.boolValue ?? false,
                    isWordPressStore: isWordPressStore?.boolValue ?? false,
                    timezone: timezone ?? "")
    }
}
