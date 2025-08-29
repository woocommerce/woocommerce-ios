import Foundation
import Storage

// MARK: - PersistedProductVariation Conversions
extension PersistedProductVariation {
    public init(from posProductVariation: POSProductVariation) {
        self.init(
            id: posProductVariation.productVariationID,
            siteID: posProductVariation.siteID,
            productID: posProductVariation.productID,
            sku: posProductVariation.sku,
            globalUniqueID: posProductVariation.globalUniqueID,
            price: posProductVariation.price,
            downloadable: posProductVariation.downloadable,
            fullDescription: posProductVariation.fullDescription,
            manageStock: posProductVariation.manageStock,
            stockQuantity: posProductVariation.stockQuantity,
            stockStatusKey: posProductVariation.stockStatusKey
        )
    }

    public func toPOSProductVariation(attributes: [ProductVariationAttribute] = [], image: ProductImage? = nil) -> POSProductVariation {
        return POSProductVariation(
            siteID: siteID,
            productID: productID,
            productVariationID: id,
            attributes: attributes,
            image: image,
            fullDescription: fullDescription,
            sku: sku,
            globalUniqueID: globalUniqueID,
            price: price,
            downloadable: downloadable,
            manageStock: manageStock,
            stockQuantity: stockQuantity,
            stockStatusKey: stockStatusKey
        )
    }

    public func toPOSProductVariation(db: GRDBDatabaseConnection) throws -> POSProductVariation {
        let image = try db.read { db in
            return try request(for: PersistedProductVariation.image).fetchOne(db)
        }
        let attributes = try db.read { db in
            return try request(for: PersistedProductVariation.attributes).fetchAll(db)
        }
        return toPOSProductVariation(
            attributes: attributes.map { $0.toProductVariationAttribute() },
            image: image?.toProductImage()
        )
    }
}

// MARK: - PersistedProductVariationAttribute Conversions
extension PersistedProductVariationAttribute {
    public init(from productVariationAttribute: ProductVariationAttribute, productVariationID: Int64) {
        self.init(
            productVariationID: productVariationID,
            name: productVariationAttribute.name,
            option: productVariationAttribute.option
        )
    }

    public func toProductVariationAttribute() -> ProductVariationAttribute {
        return ProductVariationAttribute(
            id: id ?? 0,
            name: name,
            option: option
        )
    }
}

// MARK: - PersistedProductVariationImage Conversions
extension PersistedProductVariationImage {
    public init(from productImage: ProductImage, productVariationID: Int64) {
        self.init(
            id: productImage.imageID,
            productVariationID: productVariationID,
            dateCreated: productImage.dateCreated,
            dateModified: productImage.dateModified,
            src: productImage.src,
            name: productImage.name,
            alt: productImage.alt
        )
    }

    public func toProductImage() -> ProductImage {
        return ProductImage(
            imageID: id,
            dateCreated: dateCreated,
            dateModified: dateModified,
            src: src,
            name: name,
            alt: alt
        )
    }
}
