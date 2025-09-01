import Foundation
import Storage

// MARK: - PersistedProductVariation Conversions
// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductVariation {
    init(from posProductVariation: POSProductVariation) {
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

    func toPOSProductVariation(attributes: [ProductVariationAttribute] = [], image: ProductImage? = nil) -> POSProductVariation {
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

    func toPOSProductVariation(db: GRDBDatabaseConnection) throws -> POSProductVariation {
        let (image, attributes) = try db.read { db in
            let image = try request(for: PersistedProductVariation.image).fetchOne(db)
            let attributes = try request(for: PersistedProductVariation.attributes).fetchAll(db)
            return (image, attributes)
        }

        return toPOSProductVariation(
            attributes: attributes.map { $0.toProductVariationAttribute() },
            image: image?.toProductImage()
        )
    }

}

// MARK: - POSProductVariation Storage Extensions
// periphery:ignore - TODO: remove ignore when populating database
extension POSProductVariation {
    public func save(to db: GRDBDatabaseConnection) throws {
        try db.write { db in
            let variation = PersistedProductVariation(from: self)
            try variation.insert(db)

            // Save related image if present
            if let image = self.image {
                let persistedImage = PersistedProductVariationImage(from: image, productVariationID: self.productVariationID)
                try persistedImage.insert(db)
            }

            // Save related attributes
            for attribute in self.attributes {
                var persistedAttribute = PersistedProductVariationAttribute(from: attribute, productVariationID: self.productVariationID)
                try persistedAttribute.insert(db)
            }
        }
    }
}

// MARK: - PersistedProductVariationAttribute Conversions
// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductVariationAttribute {
    init(from productVariationAttribute: ProductVariationAttribute, productVariationID: Int64) {
        self.init(
            productVariationID: productVariationID,
            name: productVariationAttribute.name,
            option: productVariationAttribute.option
        )
    }

    func toProductVariationAttribute() -> ProductVariationAttribute {
        return ProductVariationAttribute(
            id: id ?? 0,
            name: name,
            option: option
        )
    }
}

// MARK: - PersistedProductVariationImage Conversions
// periphery:ignore - TODO: remove ignore when populating database
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
