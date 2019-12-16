import Foundation
import Storage


// MARK: - Storage.TaxClass: ReadOnlyConvertible
//
extension Storage.TaxClass: ReadOnlyConvertible {

    /// Updates the Storage.TaxClass with the ReadOnly.
    ///
    public func update(with taxClass: Yosemite.TaxClass) {
        siteID = Int64(taxClass.siteID)
        name = taxClass.name
        slug = taxClass.slug
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.TaxClass {
        return TaxClass(siteID: Int(siteID), name: name, slug: slug)
    }
}
