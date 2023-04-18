import Foundation
import CoreData


extension Product {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }


    @NSManaged public var siteID: Int64
    @NSManaged public var productID: Int64
    @NSManaged public var productTypeKey: String
    @NSManaged public var name: String
    @NSManaged public var slug: String
    @NSManaged public var permalink: String
    @NSManaged public var date: Date
    @NSManaged public var dateCreated: Date
    @NSManaged public var dateModified: Date?
    @NSManaged public var dateOnSaleStart: Date?
    @NSManaged public var dateOnSaleEnd: Date?
    @NSManaged public var statusKey: String
    @NSManaged public var featured: Bool
    @NSManaged public var catalogVisibilityKey: String
    @NSManaged public var fullDescription: String?
    @NSManaged public var briefDescription: String?
    @NSManaged public var sku: String?
    @NSManaged public var price: String
    @NSManaged public var regularPrice: String?
    @NSManaged public var salePrice: String?
    @NSManaged public var onSale: Bool
    @NSManaged public var purchasable: Bool
    @NSManaged public var totalSales: Int64
    @NSManaged public var virtual: Bool
    @NSManaged public var downloadable: Bool
    @NSManaged public var downloadLimit: Int64
    @NSManaged public var downloadExpiry: Int64
    @NSManaged public var externalURL: String?
    @NSManaged public var taxStatusKey: String
    @NSManaged public var taxClass: String?
    @NSManaged public var manageStock: Bool
    @NSManaged public var stockQuantity: String?
    @NSManaged public var stockStatusKey: String
    @NSManaged public var soldIndividually: Bool
    @NSManaged public var weight: String?
    @NSManaged public var shippingRequired: Bool
    @NSManaged public var shippingTaxable: Bool
    @NSManaged public var shippingClass: String?
    @NSManaged public var shippingClassID: Int64
    @NSManaged public var reviewsAllowed: Bool
    @NSManaged public var averageRating: String
    @NSManaged public var ratingCount: Int64
    @NSManaged public var relatedIDs: [Int64]?
    @NSManaged public var upsellIDs: [Int64]?
    @NSManaged public var crossSellIDs: [Int64]?
    @NSManaged public var parentID: Int64
    @NSManaged public var purchaseNote: String?
    @NSManaged public var variations: [Int64]?
    @NSManaged public var groupedProducts: [Int64]?
    @NSManaged public var menuOrder: Int64
    @NSManaged public var backordersKey: String
    @NSManaged public var backordersAllowed: Bool
    @NSManaged public var backordered: Bool
    @NSManaged public var buttonText: String
    @NSManaged public var dimensions: ProductDimensions?
    @NSManaged public var attributes: Set<ProductAttribute>?
    @NSManaged public var categories: Set<ProductCategory>?
    @NSManaged public var defaultAttributes: Set<ProductDefaultAttribute>?
    @NSManaged public var downloads: NSOrderedSet?
    @NSManaged public var images: NSOrderedSet?
    @NSManaged public var tags: NSOrderedSet?
    @NSManaged public var searchResults: Set<ProductSearchResults>?
    @NSManaged public var productVariations: Set<ProductVariation>?
    @NSManaged public var productShippingClass: ProductShippingClass?
    @NSManaged public var addOns: NSOrderedSet?
    @NSManaged public var bundleStockQuantity: NSNumber?
    @NSManaged public var bundleStockStatus: String?
    @NSManaged public var bundledItems: NSOrderedSet?
    @NSManaged public var compositeComponents: NSOrderedSet?
    @NSManaged public var subscription: ProductSubscription?

}

// MARK: Generated accessors for attributes
extension Product {

    @objc(addAttributesObject:)
    @NSManaged public func addToAttributes(_ value: ProductAttribute)

    @objc(removeAttributesObject:)
    @NSManaged public func removeFromAttributes(_ value: ProductAttribute)

    @objc(addAttributes:)
    @NSManaged public func addToAttributes(_ values: NSSet)

    @objc(removeAttributes:)
    @NSManaged public func removeFromAttributes(_ values: NSSet)

}

// MARK: Generated accessors for categories
extension Product {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: ProductCategory)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: ProductCategory)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

// MARK: Generated accessors for defaultAttributes
extension Product {

    @objc(addDefaultAttributesObject:)
    @NSManaged public func addToDefaultAttributes(_ value: ProductDefaultAttribute)

    @objc(removeDefaultAttributesObject:)
    @NSManaged public func removeFromDefaultAttributes(_ value: ProductDefaultAttribute)

    @objc(addDefaultAttributes:)
    @NSManaged public func addToDefaultAttributes(_ values: NSSet)

    @objc(removeDefaultAttributes:)
    @NSManaged public func removeFromDefaultAttributes(_ values: NSSet)

}

// MARK: Generated accessors for downloads
extension Product {

    @objc(insertObject:inDownloadsAtIndex:)
    @NSManaged public func insertIntoDownloads(_ value: ProductDownload, at idx: Int)

    @objc(removeObjectFromDownloadsAtIndex:)
    @NSManaged public func removeFromDownloads(at idx: Int)

    @objc(insertDownloads:atIndexes:)
    @NSManaged public func insertIntoDownloads(_ values: [ProductDownload], at indexes: NSIndexSet)

    @objc(removeDownloadsAtIndexes:)
    @NSManaged public func removeFromDownloads(at indexes: NSIndexSet)

    @objc(replaceObjectInDownloadsAtIndex:withObject:)
    @NSManaged public func replaceDownloads(at idx: Int, with value: ProductDownload)

    @objc(replaceDownloadsAtIndexes:withDownloads:)
    @NSManaged public func replaceDownloads(at indexes: NSIndexSet, with values: [ProductDownload])

    @objc(addDownloadsObject:)
    @NSManaged public func addToDownloads(_ value: ProductDownload)

    @objc(removeDownloadsObject:)
    @NSManaged public func removeFromDownloads(_ value: ProductDownload)

    @objc(addDownloads:)
    @NSManaged public func addToDownloads(_ values: NSOrderedSet)

    @objc(removeDownloads:)
    @NSManaged public func removeFromDownloads(_ values: NSOrderedSet)

}

// MARK: Generated accessors for images
extension Product {

    @objc(insertObject:inImagesAtIndex:)
    @NSManaged public func insertIntoImages(_ value: ProductImage, at idx: Int)

    @objc(removeObjectFromImagesAtIndex:)
    @NSManaged public func removeFromImages(at idx: Int)

    @objc(insertImages:atIndexes:)
    @NSManaged public func insertIntoImages(_ values: [ProductImage], at indexes: NSIndexSet)

    @objc(removeImagesAtIndexes:)
    @NSManaged public func removeFromImages(at indexes: NSIndexSet)

    @objc(replaceObjectInImagesAtIndex:withObject:)
    @NSManaged public func replaceImages(at idx: Int, with value: ProductImage)

    @objc(replaceImagesAtIndexes:withImages:)
    @NSManaged public func replaceImages(at indexes: NSIndexSet, with values: [ProductImage])

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: ProductImage)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: ProductImage)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSOrderedSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSOrderedSet)

}

// MARK: Generated accessors for tags
extension Product {

    @objc(insertObject:inTagsAtIndex:)
    @NSManaged public func insertIntoTags(_ value: ProductTag, at idx: Int)

    @objc(removeObjectFromTagsAtIndex:)
    @NSManaged public func removeFromTags(at idx: Int)

    @objc(insertTags:atIndexes:)
    @NSManaged public func insertIntoTags(_ values: [ProductTag], at indexes: NSIndexSet)

    @objc(removeTagsAtIndexes:)
    @NSManaged public func removeFromTags(at indexes: NSIndexSet)

    @objc(replaceObjectInTagsAtIndex:withObject:)
    @NSManaged public func replaceTags(at idx: Int, with value: ProductTag)

    @objc(replaceTagsAtIndexes:withTags:)
    @NSManaged public func replaceTags(at indexes: NSIndexSet, with values: [ProductTag])

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: ProductTag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: ProductTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSOrderedSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSOrderedSet)

}

// MARK: Generated accessors for searchResults
extension Product {

    @objc(addSearchResultsObject:)
    @NSManaged public func addToSearchResults(_ value: ProductSearchResults)

    @objc(removeSearchResultsObject:)
    @NSManaged public func removeFromSearchResults(_ value: ProductSearchResults)

    @objc(addSearchResults:)
    @NSManaged public func addToSearchResults(_ values: NSSet)

    @objc(removeSearchResults:)
    @NSManaged public func removeFromSearchResults(_ values: NSSet)

}

// MARK: Generated accessors for productVariations
extension Product {

    @objc(addProductVariationsObject:)
    @NSManaged public func addToProductVariations(_ value: ProductVariation)

    @objc(removeProductVariationsObject:)
    @NSManaged public func removeFromProductVariations(_ value: ProductVariation)

    @objc(addProductVariations:)
    @NSManaged public func addToProductVariations(_ values: NSSet)

    @objc(removeProductVariations:)
    @NSManaged public func removeFromProductVariations(_ values: NSSet)

}

// MARK: Generated accessors for addOns
extension Product {

    @objc(addAddOnsObject:)
    @NSManaged public func addToAddOns(_ value: ProductAddOn)

    @objc(removeAddOnsObject:)
    @NSManaged public func removeFromAddOns(_ value: ProductAddOn)

    @objc(addAddOns:)
    @NSManaged public func addToAddOns(_ values: NSOrderedSet)

    @objc(removeAddOns:)
    @NSManaged public func removeFromAddOns(_ values: NSOrderedSet)

}

// MARK: Generated accessors for bundledItems
extension Product {

    @objc(insertObject:inBundledItemsAtIndex:)
    @NSManaged public func insertIntoBundledItems(_ value: ProductBundleItem, at idx: Int)

    @objc(removeObjectFromBundledItemsAtIndex:)
    @NSManaged public func removeFromBundledItems(at idx: Int)

    @objc(insertBundledItems:atIndexes:)
    @NSManaged public func insertIntoBundledItems(_ values: [ProductBundleItem], at indexes: NSIndexSet)

    @objc(removeBundledItemsAtIndexes:)
    @NSManaged public func removeFromBundledItems(at indexes: NSIndexSet)

    @objc(replaceObjectInBundledItemsAtIndex:withObject:)
    @NSManaged public func replaceBundledItems(at idx: Int, with value: ProductBundleItem)

    @objc(replaceBundledItemsAtIndexes:withBundledItems:)
    @NSManaged public func replaceBundledItems(at indexes: NSIndexSet, with values: [ProductBundleItem])

    @objc(addBundledItemsObject:)
    @NSManaged public func addToBundledItems(_ value: ProductBundleItem)

    @objc(removeBundledItemsObject:)
    @NSManaged public func removeFromBundledItems(_ value: ProductBundleItem)

    @objc(addBundledItems:)
    @NSManaged public func addToBundledItems(_ values: NSOrderedSet)

    @objc(removeBundledItems:)
    @NSManaged public func removeFromBundledItems(_ values: NSOrderedSet)

}

// MARK: Generated accessors for compositeComponents
extension Product {

    @objc(insertObject:inCompositeComponentsAtIndex:)
    @NSManaged public func insertIntoCompositeComponents(_ value: ProductCompositeComponent, at idx: Int)

    @objc(removeObjectFromCompositeComponentsAtIndex:)
    @NSManaged public func removeFromCompositeComponents(at idx: Int)

    @objc(insertCompositeComponents:atIndexes:)
    @NSManaged public func insertIntoCompositeComponents(_ values: [ProductCompositeComponent], at indexes: NSIndexSet)

    @objc(removeCompositeComponentsAtIndexes:)
    @NSManaged public func removeFromCompositeComponents(at indexes: NSIndexSet)

    @objc(replaceObjectInCompositeComponentsAtIndex:withObject:)
    @NSManaged public func replaceCompositeComponents(at idx: Int, with value: ProductCompositeComponent)

    @objc(replaceCompositeComponentsAtIndexes:withCompositeComponents:)
    @NSManaged public func replaceCompositeComponents(at indexes: NSIndexSet, with values: [ProductCompositeComponent])

    @objc(addCompositeComponentsObject:)
    @NSManaged public func addToCompositeComponents(_ value: ProductCompositeComponent)

    @objc(removeCompositeComponentsObject:)
    @NSManaged public func removeFromCompositeComponents(_ value: ProductCompositeComponent)

    @objc(addCompositeComponents:)
    @NSManaged public func addToCompositeComponents(_ values: NSOrderedSet)

    @objc(removeCompositeComponents:)
    @NSManaged public func removeFromCompositeComponents(_ values: NSOrderedSet)

}
