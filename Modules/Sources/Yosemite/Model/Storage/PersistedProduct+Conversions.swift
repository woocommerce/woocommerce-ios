import Foundation
import Storage

// MARK: - PersistedProduct Conversions
extension PersistedProduct {
    public init(from posProduct: POSProduct) {
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

    public func toPOSProduct(images: [ProductImage] = [], attributes: [ProductAttribute] = []) -> POSProduct {
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
}

// MARK: - PersistedProductAttribute Conversions
extension PersistedProductAttribute {
    public init(from productAttribute: ProductAttribute, productID: Int64) {
        self.init(
            productID: productID,
            name: productAttribute.name,
            position: Int64(productAttribute.position),
            visible: productAttribute.visible,
            variation: productAttribute.variation,
            options: productAttribute.options
        )
    }

    public func toProductAttribute(siteID: Int64) -> ProductAttribute {
        return ProductAttribute(
            siteID: siteID,
            attributeID: id ?? 0,
            name: name,
            position: Int(position),
            visible: visible,
            variation: variation,
            options: options
        )
    }
}

// MARK: - PersistedProductImage Conversions
extension PersistedProductImage {
    public init(from productImage: ProductImage, productID: Int64) {
        self.init(
            id: productImage.imageID,
            productID: productID,
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
