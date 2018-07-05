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
        isWordPressStore = site.isWordPressStore
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Site {
        return Site(siteID: Int(siteID),
                    name: name ?? "",
                    description: tagline ?? "",
                    url: url ?? "",
                    isWordPressStore: isWordPressStore)
    }
}
