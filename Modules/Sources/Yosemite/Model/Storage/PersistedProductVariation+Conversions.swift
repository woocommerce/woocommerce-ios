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
                // Insert or update the image itself
                let persistedImage = PersistedImage.make(from: image, siteID: self.siteID)
                try persistedImage.save(db)

                // Create join table entry
                let joinEntry = PersistedProductVariationImage(siteID: self.siteID,
                                                              productVariationID: self.productVariationID,
                                                              imageID: image.imageID)
                try joinEntry.insert(db)
            }

            // Save related attributes
            for attribute in self.attributes {
                var persistedAttribute = PersistedProductVariationAttribute(from: attribute, siteID: self.siteID, productVariationID: self.productVariationID)
                try persistedAttribute.insert(db)
            }
        }
    }
}

// MARK: - PersistedProductVariationAttribute Conversions
// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductVariationAttribute {
    init(from productVariationAttribute: ProductVariationAttribute, siteID: Int64, productVariationID: Int64) {
        self.init(
            siteID: siteID,
            productVariationID: productVariationID,
            remoteAttributeID: productVariationAttribute.id,
            name: productVariationAttribute.name,
            option: productVariationAttribute.option
        )
    }

    func toProductVariationAttribute() -> ProductVariationAttribute {
        return ProductVariationAttribute(
            id: remoteAttributeID,
            name: name,
            option: option
        )
    }
}
