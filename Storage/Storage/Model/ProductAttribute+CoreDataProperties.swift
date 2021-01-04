import Foundation
import CoreData


extension ProductAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductAttribute> {
        return NSFetchRequest<ProductAttribute>(entityName: "ProductAttribute")
    }

    @NSManaged public var siteID: Int64
    @NSManaged public var attributeID: Int64
    @NSManaged public var name: String
    @NSManaged public var position: Int64
    @NSManaged public var visible: Bool
    @NSManaged public var variation: Bool
    @NSManaged public var options: [String]?
    @NSManaged public var product: Product?
    @NSManaged public var terms: Set<ProductAttributeTerm>?
}

// MARK: Generated accessors for products
extension ProductAttribute {

    @objc(addTermsObject:)
    @NSManaged public func addToTerms(_ value: ProductAttributeTerm)

    @objc(removeTermsObject:)
    @NSManaged public func removeFromTerms(_ value: ProductAttributeTerm)

    @objc(addTerms:)
    @NSManaged public func addToTerms(_ values: NSSet)

    @objc(removeTerms:)
    @NSManaged public func removeFromTerms(_ values: NSSet)
}
