import Foundation
import Storage

// MARK: - PersistedProduct Conversions
// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProduct {
    init(from posProduct: POSProduct) {
        self.init(
            id: posProduct.productID,
            siteID: posProduct.siteID,
            name: posProduct.name,
            productTypeKey: posProduct.productTypeKey,
            fullDescription: posProduct.fullDescription,
            shortDescription: posProduct.shortDescription,
            sku: posProduct.sku,
            globalUniqueID: posProduct.globalUniqueID,
            price: posProduct.price,
            downloadable: posProduct.downloadable,
            parentID: posProduct.parentID,
            manageStock: posProduct.manageStock,
            stockQuantity: posProduct.stockQuantity,
            stockStatusKey: posProduct.stockStatusKey
        )
    }

    func toPOSProduct(images: [ProductImage] = [], attributes: [ProductAttribute] = []) -> POSProduct {
        return POSProduct(
            siteID: siteID,
            productID: id,
            name: name,
            productTypeKey: productTypeKey,
            fullDescription: fullDescription,
            shortDescription: shortDescription,
            sku: sku,
            globalUniqueID: globalUniqueID,
            price: price,
            downloadable: downloadable,
            parentID: parentID,
            images: images,
            attributes: attributes,
            manageStock: manageStock,
            stockQuantity: stockQuantity,
            stockStatusKey: stockStatusKey
        )
    }

    func toPOSProduct(db: GRDBDatabaseConnection) throws -> POSProduct {
        let (images, attributes) = try db.read { db in
            let images = try request(for: PersistedProduct.images).fetchAll(db)
            let attributes = try request(for: PersistedProduct.attributes).fetchAll(db)
            return (images, attributes)
        }

        return toPOSProduct(
            images: images.map { $0.toProductImage() },
            attributes: attributes.map { $0.toProductAttribute(siteID: siteID) }
        )
    }

}

// MARK: - POSProduct Storage Extensions
// periphery:ignore - TODO: remove ignore when populating database
extension POSProduct {
    public func save(to db: GRDBDatabaseConnection) throws {
        try db.write { db in
            let product = PersistedProduct(from: self)
            try product.insert(db)

            // Save related images
            for image in self.images {
                let persistedImage = PersistedProductImage(from: image, siteID: self.siteID, productID: self.productID)
                try persistedImage.insert(db)
            }

            // Save related attributes
            for attribute in self.attributes {
                var persistedAttribute = PersistedProductAttribute(from: attribute, siteID: self.siteID, productID: self.productID)
                try persistedAttribute.insert(db)
            }
        }
    }
}

// MARK: - PersistedProductAttribute Conversions
// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductAttribute {
    init(from productAttribute: ProductAttribute, siteID: Int64, productID: Int64) {
        self.init(
            siteID: siteID,
            productID: productID,
            remoteAttributeID: productAttribute.attributeID,
            name: productAttribute.name,
            position: Int64(productAttribute.position),
            visible: productAttribute.visible,
            variation: productAttribute.variation,
            options: productAttribute.options
        )
    }

    func toProductAttribute(siteID: Int64) -> ProductAttribute {
        return ProductAttribute(
            siteID: siteID,
            attributeID: remoteAttributeID,
            name: name,
            position: Int(position),
            visible: visible,
            variation: variation,
            options: options
        )
    }
}

// MARK: - PersistedProductImage Conversions
// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductImage {
    init(from productImage: ProductImage, siteID: Int64, productID: Int64) {
        self.init(
            siteID: siteID,
            id: productImage.imageID,
            productID: productID,
            dateCreated: productImage.dateCreated,
            dateModified: productImage.dateModified,
            src: productImage.src,
            name: productImage.name,
            alt: productImage.alt
        )
    }

    func toProductImage() -> ProductImage {
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
