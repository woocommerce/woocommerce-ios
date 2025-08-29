import Foundation
import Testing
@testable import Yosemite

struct PersistedProductVariationConversionsTests {

    @Test("PersistedProductVariation init(from:) maps all POSProductVariation fields")
    func test_variation_init_from_posProductVariation_maps_all_fields() throws {
        // Given
        let siteID: Int64 = 5
        let productID: Int64 = 50
        let variationID: Int64 = 500
        let attrs = [
            ProductVariationAttribute(id: 0, name: "Color", option: "Green"),
            ProductVariationAttribute(id: 0, name: "Size", option: "XL")
        ]
        let image = ProductImage(imageID: 501,
                                 dateCreated: Date(timeIntervalSince1970: 1000),
                                 dateModified: nil,
                                 src: "https://example.com/v.png",
                                 name: "v",
                                 alt: nil)
        let pos = POSProductVariation(
            siteID: siteID,
            productID: productID,
            productVariationID: variationID,
            attributes: attrs,
            image: image,
            fullDescription: "VFull",
            sku: "VSKU",
            globalUniqueID: "VGID",
            price: "19.95",
            downloadable: false,
            manageStock: true,
            stockQuantity: 2,
            stockStatusKey: "instock"
        )

        // When
        let persisted = PersistedProductVariation(from: pos)

        // Then
        #expect(persisted.id == variationID)
        #expect(persisted.siteID == siteID)
        #expect(persisted.productID == productID)
        #expect(persisted.sku == pos.sku)
        #expect(persisted.globalUniqueID == pos.globalUniqueID)
        #expect(persisted.price == pos.price)
        #expect(persisted.downloadable == pos.downloadable)
        #expect(persisted.fullDescription == pos.fullDescription)
        #expect(persisted.manageStock == pos.manageStock)
        #expect(persisted.stockQuantity == pos.stockQuantity)
        #expect(persisted.stockStatusKey == pos.stockStatusKey)
    }

    @Test("PersistedProductVariation toPOSProductVariation maps back with attributes and optional image")
    func test_variation_toPOSProductVariation_maps_back_including_attributes_and_image() throws {
        // Given
        let siteID: Int64 = 6
        let productID: Int64 = 60
        let variationID: Int64 = 600
        let persisted = PersistedProductVariation(
            id: variationID,
            siteID: siteID,
            productID: productID,
            sku: "SKU",
            globalUniqueID: "GID",
            price: "11.00",
            downloadable: true,
            fullDescription: "Full",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "outofstock"
        )

        let varAttrs = [
            PersistedProductVariationAttribute(productVariationID: variationID, name: "Material", option: "Wool"),
            PersistedProductVariationAttribute(productVariationID: variationID, name: "Fit", option: "Slim")
        ]
        let varImage = PersistedProductVariationImage(
            id: 601,
            productVariationID: variationID,
            dateCreated: Date(timeIntervalSince1970: 2000),
            dateModified: Date(timeIntervalSince1970: 3000),
            src: "https://example.com/vi.png",
            name: "vi",
            alt: "vai")

        // When
        let pos = persisted.toPOSProductVariation(
            attributes: varAttrs.map { $0.toProductVariationAttribute() },
            image: varImage.toProductImage()
        )

        // Then
        #expect(pos.siteID == siteID)
        #expect(pos.productID == productID)
        #expect(pos.productVariationID == variationID)
        #expect(pos.sku == persisted.sku)
        #expect(pos.globalUniqueID == persisted.globalUniqueID)
        #expect(pos.price == persisted.price)
        #expect(pos.downloadable == persisted.downloadable)
        #expect(pos.fullDescription == persisted.fullDescription)
        #expect(pos.manageStock == persisted.manageStock)
        #expect(pos.stockQuantity == persisted.stockQuantity)
        #expect(pos.stockStatusKey == persisted.stockStatusKey)
        #expect(pos.attributes.count == 2)
        #expect(pos.image?.imageID == varImage.id)
    }

    @Test("PersistedProductVariationAttribute init(from:) and toProductVariationAttribute round-trip")
    func test_variation_attribute_round_trip() throws {
        // Given
        let variationID: Int64 = 700
        let attr = ProductVariationAttribute(id: 0, name: "Style", option: "Modern")

        // When
        let persisted = PersistedProductVariationAttribute(from: attr, productVariationID: variationID)
        let back = persisted.toProductVariationAttribute()

        // Then
        #expect(persisted.productVariationID == variationID)
        #expect(persisted.name == attr.name)
        #expect(persisted.option == attr.option)

        #expect(back.name == attr.name)
        #expect(back.option == attr.option)
    }

    @Test("PersistedProductVariationImage init(from:) and toProductImage round-trip")
    func test_variation_image_round_trip() throws {
        // Given
        let variationID: Int64 = 800
        let image = ProductImage(imageID: 801,
                                 dateCreated: Date(timeIntervalSince1970: 4000),
                                 dateModified: nil,
                                 src: "https://example.com/img.png",
                                 name: nil,
                                 alt: nil)

        // When
        let persisted = PersistedProductVariationImage(from: image, productVariationID: variationID)
        let back = persisted.toProductImage()

        // Then
        #expect(persisted.id == image.imageID)
        #expect(persisted.productVariationID == variationID)
        #expect(persisted.dateCreated == image.dateCreated)
        #expect(persisted.dateModified == image.dateModified)
        #expect(persisted.src == image.src)
        #expect(persisted.name == image.name)
        #expect(persisted.alt == image.alt)

        #expect(back.imageID == image.imageID)
        #expect(back.dateCreated == image.dateCreated)
        #expect(back.dateModified == image.dateModified)
        #expect(back.src == image.src)
        #expect(back.name == image.name)
        #expect(back.alt == image.alt)
    }
}
