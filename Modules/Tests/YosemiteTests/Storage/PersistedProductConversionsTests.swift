import Foundation
import Testing
@testable import Yosemite

struct PersistedProductConversionsTests {

    @Test("PersistedProduct init(from:) maps all POSProduct fields")
    func test_product_init_from_posProduct_maps_all_fields() throws {
        // Given
        let siteID: Int64 = 1
        let productID: Int64 = 10
        let images: [ProductImage] = [
            ProductImage(imageID: 100,
                         dateCreated: Date(timeIntervalSince1970: 1),
                         dateModified: nil,
                         src: "https://example.com/1.png",
                         name: "img1",
                         alt: "alt1"),
            ProductImage(imageID: 101,
                         dateCreated: Date(timeIntervalSince1970: 2),
                         dateModified: Date(timeIntervalSince1970: 3),
                         src: "https://example.com/2.png",
                         name: "img2",
                         alt: nil)
        ]
        let attributes: [ProductAttribute] = [
            ProductAttribute(siteID: siteID, attributeID: 0, name: "Color", position: 0, visible: true, variation: true, options: ["Red", "Blue"]),
            ProductAttribute(siteID: siteID, attributeID: 0, name: "Size", position: 1, visible: false, variation: false, options: ["S", "M"])
        ]
        let pos = POSProduct(
            siteID: siteID,
            productID: productID,
            name: "Test Product",
            productTypeKey: "simple",
            fullDescription: "Full",
            shortDescription: "Short",
            sku: "SKU-123",
            globalUniqueID: "GID-1",
            price: "9.99",
            downloadable: false,
            parentID: 0,
            images: images,
            attributes: attributes,
            manageStock: true,
            stockQuantity: 5,
            stockStatusKey: "instock"
        )

        // When
        let persisted = PersistedProduct(from: pos)

        // Then
        #expect(persisted.id == productID)
        #expect(persisted.siteID == siteID)
        #expect(persisted.name == pos.name)
        #expect(persisted.productTypeKey == pos.productTypeKey)
        #expect(persisted.fullDescription == pos.fullDescription)
        #expect(persisted.shortDescription == pos.shortDescription)
        #expect(persisted.sku == pos.sku)
        #expect(persisted.globalUniqueID == pos.globalUniqueID)
        #expect(persisted.price == pos.price)
        #expect(persisted.downloadable == pos.downloadable)
        #expect(persisted.parentID == pos.parentID)
        #expect(persisted.manageStock == pos.manageStock)
        #expect(persisted.stockQuantity == pos.stockQuantity)
        #expect(persisted.stockStatusKey == pos.stockStatusKey)
    }

    @Test("PersistedProduct toPOSProduct maps back with images and attributes")
    func test_product_toPOSProduct_maps_back_including_images_and_attributes() throws {
        // Given
        let siteID: Int64 = 2
        let productID: Int64 = 20
        let persisted = PersistedProduct(
            id: productID,
            siteID: siteID,
            name: "Prod",
            productTypeKey: "variable",
            fullDescription: "FullD",
            shortDescription: "ShortD",
            sku: nil,
            globalUniqueID: nil,
            price: "12.34",
            downloadable: true,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "outofstock"
        )

        let productImages = [
            PersistedProductImage(id: 200,
                                  productID: productID,
                                  dateCreated: Date(timeIntervalSince1970: 10),
                                  dateModified: nil,
                                  src: "https://example.com/p1.png",
                                  name: "p1",
                                  alt: "a1"),
            PersistedProductImage(id: 201,
                                  productID: productID,
                                  dateCreated: Date(timeIntervalSince1970: 11),
                                  dateModified: Date(timeIntervalSince1970: 12),
                                  src: "https://example.com/p2.png",
                                  name: nil,
                                  alt: nil)
        ]

        let persistedAttributes = [
            PersistedProductAttribute(productID: productID, name: "Material", position: 0, visible: true, variation: false, options: ["Cotton"]),
            PersistedProductAttribute(productID: productID, name: "Fit", position: 1, visible: true, variation: true, options: ["Slim", "Regular"])
        ]

        // When
        let pos = persisted.toPOSProduct(
            images: productImages.map { $0.toProductImage() },
            attributes: persistedAttributes.map { $0.toProductAttribute(siteID: siteID) }
        )

        // Then
        #expect(pos.siteID == siteID)
        #expect(pos.productID == productID)
        #expect(pos.name == persisted.name)
        #expect(pos.productTypeKey == persisted.productTypeKey)
        #expect(pos.fullDescription == persisted.fullDescription)
        #expect(pos.shortDescription == persisted.shortDescription)
        #expect(pos.sku == persisted.sku)
        #expect(pos.globalUniqueID == persisted.globalUniqueID)
        #expect(pos.price == persisted.price)
        #expect(pos.downloadable == persisted.downloadable)
        #expect(pos.parentID == persisted.parentID)
        #expect(pos.manageStock == persisted.manageStock)
        #expect(pos.stockQuantity == persisted.stockQuantity)
        #expect(pos.stockStatusKey == persisted.stockStatusKey)
        #expect(pos.images.count == 2)
        #expect(pos.attributes.count == 2)
        #expect(pos.attributesForVariations.count == 1)
    }

    @Test("PersistedProductAttribute init(from:) and toProductAttribute round-trip")
    func test_product_attribute_round_trip() throws {
        // Given
        let siteID: Int64 = 3
        let productID: Int64 = 30
        let attribute = ProductAttribute(siteID: siteID,
                                         attributeID: 0,
                                         name: "Flavor",
                                         position: 2,
                                         visible: true,
                                         variation: true,
                                         options: ["Vanilla", "Chocolate"])

        // When
        let persisted = PersistedProductAttribute(from: attribute, productID: productID)
        let back = persisted.toProductAttribute(siteID: siteID)

        // Then
        #expect(persisted.productID == productID)
        #expect(persisted.name == attribute.name)
        #expect(persisted.position == Int64(attribute.position))
        #expect(persisted.visible == attribute.visible)
        #expect(persisted.variation == attribute.variation)
        #expect(persisted.options == attribute.options)

        #expect(back.siteID == siteID)
        #expect(back.name == attribute.name)
        #expect(back.position == attribute.position)
        #expect(back.visible == attribute.visible)
        #expect(back.variation == attribute.variation)
        #expect(back.options == attribute.options)
    }

    @Test("PersistedProductImage init(from:) and toProductImage round-trip")
    func test_product_image_round_trip() throws {
        // Given
        let productID: Int64 = 40
        let image = ProductImage(imageID: 400,
                                 dateCreated: Date(timeIntervalSince1970: 100),
                                 dateModified: Date(timeIntervalSince1970: 200),
                                 src: "https://example.com/x.png",
                                 name: "x",
                                 alt: "y")

        // When
        let persisted = PersistedProductImage(from: image, productID: productID)
        let back = persisted.toProductImage()

        // Then
        #expect(persisted.id == image.imageID)
        #expect(persisted.productID == productID)
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
