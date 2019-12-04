import Foundation
import Storage

// MARK: - Storage.ProductShippingClass: ReadOnlyConvertible
//
extension Storage.ProductShippingClass: ReadOnlyConvertible {

    /// Updates the Storage.ProductShippingClass with the ReadOnly.
    ///
    public func update(with productShippingClass: Yosemite.ProductShippingClass) {
        // Entities.
        count = productShippingClass.count
        descriptionHTML = productShippingClass.descriptionHTML
        name = productShippingClass.name
        shippingClassID = productShippingClass.shippingClassID
        siteID = productShippingClass.siteID
        slug = productShippingClass.slug
    }


    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductShippingClass {
        return ProductShippingClass(count: count,
                                    descriptionHTML: descriptionHTML,
                                    name: name,
                                    shippingClassID: shippingClassID,
                                    siteID: siteID,
                                    slug: slug)
    }
}
