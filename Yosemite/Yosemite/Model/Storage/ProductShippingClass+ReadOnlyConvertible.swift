import Foundation
import Storage

// MARK: - Storage.ProductShippingClass: ReadOnlyConvertible
//
extension Storage.ProductShippingClass: ReadOnlyConvertible {

    /// Updates the Storage.ProductShippingClass with the ReadOnly.
    ///
    public func update(with productShippingClass: Yosemite.ProductShippingClass) {
        shippingClassID = productShippingClass.shippingClassID
        siteID = productShippingClass.siteID
        name = productShippingClass.name
        slug = productShippingClass.slug
        descriptionHTML = productShippingClass.descriptionHTML
        count = productShippingClass.count
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductShippingClass {
        return ProductShippingClass(shippingClassID: shippingClassID,
                                    siteID: siteID,
                                    name: name,
                                    slug: slug,
                                    descriptionHTML: descriptionHTML,
                                    count: count)
    }
}
