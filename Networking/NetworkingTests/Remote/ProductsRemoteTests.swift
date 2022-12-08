import XCTest
@testable import Networking


/// ProductsRemoteTests
///
final class ProductsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Dummy Product ID
    ///
    let sampleProductID: Int64 = 282

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Add Product

    func test_addProduct_with_success_mock_returns_a_product() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "product-add-or-delete")

        // When
        let product = sampleProduct()
        let addedProduct = try await remote.addProduct(product: product)

        // Then
        let expectedProduct = Product(siteID: sampleSiteID,
                                      productID: 3007,
                                      name: "Product",
                                      slug: "product",
                                      permalink: "https://example.com/product/product/",
                                      date: DateFormatter.dateFromString(with: "2020-09-03T02:52:44"),
                                      dateCreated: DateFormatter.dateFromString(with: "2020-09-03T02:52:44"),
                                      dateModified: DateFormatter.dateFromString(with: "2020-09-03T02:52:44"),
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      productTypeKey: ProductType.simple.rawValue,
                                      statusKey: ProductStatus.published.rawValue,
                                      featured: false,
                                      catalogVisibilityKey: ProductCatalogVisibility.visible.rawValue,
                                      fullDescription: "",
                                      shortDescription: "",
                                      sku: "",
                                      price: "",
                                      regularPrice: "",
                                      salePrice: "",
                                      onSale: false,
                                      purchasable: false,
                                      totalSales: 0,
                                      virtual: false,
                                      downloadable: false,
                                      downloads: [],
                                      downloadLimit: -1,
                                      downloadExpiry: -1,
                                      buttonText: "",
                                      externalURL: "",
                                      taxStatusKey: ProductTaxStatus.taxable.rawValue,
                                      taxClass: "",
                                      manageStock: false,
                                      stockQuantity: nil,
                                      stockStatusKey: ProductStockStatus.inStock.rawValue,
                                      backordersKey: ProductBackordersSetting.notAllowed.rawValue,
                                      backordersAllowed: false,
                                      backordered: false,
                                      soldIndividually: false,
                                      weight: "",
                                      dimensions: ProductDimensions(length: "", width: "", height: ""),
                                      shippingRequired: true,
                                      shippingTaxable: true,
                                      shippingClass: "",
                                      shippingClassID: 0,
                                      productShippingClass: nil,
                                      reviewsAllowed: true,
                                      averageRating: "0",
                                      ratingCount: 0,
                                      relatedIDs: [],
                                      upsellIDs: [],
                                      crossSellIDs: [],
                                      parentID: 0,
                                      purchaseNote: "",
                                      categories: [],
                                      tags: [],
                                      images: [],
                                      attributes: [],
                                      defaultAttributes: [],
                                      variations: [],
                                      groupedProducts: [],
                                      menuOrder: 0,
                                      addOns: [])
        XCTAssertEqual(addedProduct, expectedProduct)
    }

    func test_addProduct_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        let product = sampleProduct()
        var addedProduct: Product?
        var result: Error?

        do {
            addedProduct = try await remote.addProduct(product: product)
        } catch {
            result = error
        }

        XCTAssertNil(addedProduct)
        XCTAssertEqual(result as? NetworkError, NetworkError.notFound)
    }

    // MARK: - Delete Product

    func test_deleteProduct_with_success_mock_returns_a_product() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        /// When we delete a product, it return the deleted product.
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-add-or-delete")

        // When
        let deletedProduct = try await remote.deleteProduct(for: sampleSiteID, productID: sampleProductID)

        // Then
        let expectedProduct = Product(siteID: sampleSiteID,
                                      productID: 3007,
                                      name: "Product",
                                      slug: "product",
                                      permalink: "https://example.com/product/product/",
                                      date: DateFormatter.dateFromString(with: "2020-09-03T02:52:44"),
                                      dateCreated: DateFormatter.dateFromString(with: "2020-09-03T02:52:44"),
                                      dateModified: DateFormatter.dateFromString(with: "2020-09-03T02:52:44"),
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      productTypeKey: ProductType.simple.rawValue,
                                      statusKey: ProductStatus.published.rawValue,
                                      featured: false,
                                      catalogVisibilityKey: ProductCatalogVisibility.visible.rawValue,
                                      fullDescription: "",
                                      shortDescription: "",
                                      sku: "",
                                      price: "",
                                      regularPrice: "",
                                      salePrice: "",
                                      onSale: false,
                                      purchasable: false,
                                      totalSales: 0,
                                      virtual: false,
                                      downloadable: false,
                                      downloads: [],
                                      downloadLimit: -1,
                                      downloadExpiry: -1,
                                      buttonText: "",
                                      externalURL: "",
                                      taxStatusKey: ProductTaxStatus.taxable.rawValue,
                                      taxClass: "",
                                      manageStock: false,
                                      stockQuantity: nil,
                                      stockStatusKey: ProductStockStatus.inStock.rawValue,
                                      backordersKey: ProductBackordersSetting.notAllowed.rawValue,
                                      backordersAllowed: false,
                                      backordered: false,
                                      soldIndividually: false,
                                      weight: "",
                                      dimensions: ProductDimensions(length: "", width: "", height: ""),
                                      shippingRequired: true,
                                      shippingTaxable: true,
                                      shippingClass: "",
                                      shippingClassID: 0,
                                      productShippingClass: nil,
                                      reviewsAllowed: true,
                                      averageRating: "0",
                                      ratingCount: 0,
                                      relatedIDs: [],
                                      upsellIDs: [],
                                      crossSellIDs: [],
                                      parentID: 0,
                                      purchaseNote: "",
                                      categories: [],
                                      tags: [],
                                      images: [],
                                      attributes: [],
                                      defaultAttributes: [],
                                      variations: [],
                                      groupedProducts: [],
                                      menuOrder: 0,
                                      addOns: [])
        XCTAssertEqual(deletedProduct, expectedProduct)
    }

    func test_deleteProduct_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        var deletedProduct: Product?
        var result: Error?

        do {
            deletedProduct = try await remote.deleteProduct(for: sampleSiteID, productID: sampleProductID)
        } catch {
            result = error
        }

        // Then
        XCTAssertNil(deletedProduct)
        XCTAssertEqual(result as? NetworkError, NetworkError.notFound)
    }

    // MARK: - Load all products tests

    /// Verifies that loadAllProducts properly parses the `products-load-all` sample response.
    ///
    func test_loadAllProducts_returns_all_parsed_products() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")

        // When
        let products = try await remote.loadAllProducts(for: sampleSiteID)

        // Then
        XCTAssertEqual(products.count, 10)
    }

    /// Verifies that loadAllProducts with `excludedProductIDs` makes a network request with the corresponding parameter.
    ///
    func test_loadAllProducts_with_excludedProductIDs_includes_excludeParam_in_networkRequest() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        let excludedProductIDs: [Int64] = [17, 671]

        // When
        let _ = try await remote.loadAllProducts(for: sampleSiteID, excludedProductIDs: excludedProductIDs)
        let queryParameters = try XCTUnwrap(network.queryParameters)
        let expectedParam = "exclude=17,671"

        // Then
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    /// Verifies that loadAllProducts properly relays Networking Layer errors.
    ///
    func test_loadAllProducts_properly_relays_NetwokingErrors() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        var products: [Product]?
        var expectedResult: Error?

        // When
        do {
            products = try await remote.loadAllProducts(for: sampleSiteID)
        } catch {
            expectedResult = error
        }

        // Then
        XCTAssertNil(products)
        XCTAssertEqual(expectedResult as? NetworkError, NetworkError.notFound)
    }


    // MARK: - Load single product tests

    /// Verifies that loadProduct properly parses the `product` sample response.
    ///
    func test_loadProduct_when_loads_single_product_then_returns_parsed_product() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product")

        // When
        let loadedProduct = try await remote.loadProduct(for: sampleSiteID, productID: sampleProductID)

        // Then
        XCTAssertEqual(loadedProduct.productID, sampleProductID)
    }

    /// Verifies that loadProduct properly parses the `product-external` sample response.
    ///
    func test_loadProduct_when_loads_external_product_then_returns_parsed_product() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-external")

        // When
        let loadedExternalProduct = try await remote.loadProduct(for: sampleSiteID, productID: sampleProductID)

        // Then
        XCTAssertEqual(loadedExternalProduct.productID, sampleProductID)
        XCTAssertEqual(loadedExternalProduct.buttonText, "Hit the slopes")
        XCTAssertEqual(loadedExternalProduct.externalURL, "https://snowboarding.com/product/rentals/")
    }

    /// Verifies that loadProduct properly relays any Networking Layer errors.
    ///
    func test_loadProduct_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        var loadedProduct: Product?
        var result: Error?
        do {
            loadedProduct = try await remote.loadProduct(for: sampleSiteID, productID: sampleProductID)
        } catch {
            result = error
        }

        // Then
        XCTAssertNil(loadedProduct)
        XCTAssertEqual(result as? NetworkError, NetworkError.notFound)
    }

    // MARK: - Search Products

    /// Verifies that searchProducts properly parses the `products-load-all` sample response.
    ///
    func test_searchProducts_properly_returns_parsed_products() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-search-photo")

        // When
        let products = try await remote.searchProductsBySKU(for: sampleSiteID,
                                   keyword: "photo",
                                   pageNumber: 0,
                                   pageSize: 100)

        // Then
        XCTAssertEqual(products.count, 2)
    }

    /// Verifies that searchProducts properly relays Networking Layer errors.
    ///
    func test_searchProducts_properly_relays_networking_errors() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        var result: Error?

        // When
        do {
            let _ = try await remote.searchProducts(for: self.sampleSiteID,
                                                           keyword: String(),
                                                           pageNumber: 0,
                                                           pageSize: 100)
        } catch {
            result = error
        }

        XCTAssertEqual(result as? NetworkError, NetworkError.notFound)
    }

    // MARK: - Search Products by SKU

    func test_searchProductsBySKU_properly_returns_parsed_products() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-sku-search")

        // When
        let products = try await remote.searchProductsBySKU(for: self.sampleSiteID,
                                   keyword: "choco",
                                   pageNumber: 0,
                                   pageSize: 100)
        // Then
        XCTAssertEqual(products.count, 1)
    }

    func test_searchProductsBySKU_properly_relays_networking_errors() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        var result: Error?

        // When
        do {
            let _ = try await remote.searchProductsBySKU(for: self.sampleSiteID,
                                       keyword: String(),
                                       pageNumber: 0,
                                       pageSize: 100)
        } catch {
            result = error
        }

        // Then
        XCTAssertEqual(result as? NetworkError, NetworkError.notFound)
    }


    // MARK: - Search Product SKU tests

    /// Verifies that searchSku properly parses the product `sku` sample response.
    ///
    func test_searchSku_properly_returns_parsed_sku() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "product-search-sku")
        let expectedSku = "T-SHIRT-HAPPY-NINJA"

        // When
        let sku = try await remote.searchSku(for: self.sampleSiteID, sku: expectedSku)

        // Then
        XCTAssertEqual(sku, expectedSku)
    }

    /// Verifies that searchSku properly relays Networking Layer errors.
    ///
    func test_searchSku_properly_relays_netwoking_errors() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let skuToSearch = "T-SHIRT-HAPPY-NINJA"
        var result: Error?

        // When
        do {
            let _ = try await remote.searchSku(for: self.sampleSiteID, sku: skuToSearch)
        } catch {
            result = error
        }

        // Then
        XCTAssertEqual(result as? NetworkError, NetworkError.notFound)
    }


    // MARK: - Update Product

    /// Verifies that updateProduct properly parses the `product-update` sample response.
    ///
    func test_updateProduct_returns_parsed_product() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-update")

        let productName = "This is my new product name!"
        let productDescription = "Learn something!"

        // When
        let product = sampleProduct()
        let updatedProduct = try await remote.updateProduct(product: product)

        // Then
        XCTAssertEqual(updatedProduct.name, productName)
        XCTAssertEqual(updatedProduct.fullDescription, productDescription)
    }

    /// Verifies that updateProduct properly relays Networking Layer errors.
    ///
    func test_updateProduct_relays_NetwokingErrors() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        var result: Error?

        // When
        do {
            let product = sampleProduct()
            let _ = try await remote.updateProduct(product: product)
        } catch {
            result = error
        }

        // Then
        XCTAssertEqual(result as? NetworkError, NetworkError.notFound)
    }

    // MARK: - Update Product Images

    /// Verifies that updateProductImages properly parses the `product-update` sample response.
    ///
    func test_updateProductImages_properly_returns_parsed_product() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-update")

        // When
        let product = try await remote.updateProductImages(siteID: self.sampleSiteID, productID: self.sampleProductID, images: [])

        // Then
        XCTAssertEqual(product.images.map { $0.imageID }, [1043, 1064])
    }

    /// Verifies that updateProductImages properly relays Networking Layer errors.
    ///
    func test_updateProductImages_properly_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        var result: Error?

        // When
        do {
            let _ = try await remote.updateProductImages(siteID: self.sampleSiteID, productID: self.sampleProductID, images: [])
        } catch {
            result = error
        }

        // Then
        XCTAssertEqual(result as? NetworkError, NetworkError.notFound)
    }

    // MARK: - Product IDs

    /// Verifies that loadProductIDs properly parses the `products-ids-only` sample response.
    ///
    func test_loadProductIDs_properly_returns_parsed_ids() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-ids-only")

        // When
        let productIDs = try await remote.loadProductIDs(for: self.sampleSiteID)

        // Then
        XCTAssertEqual(productIDs, [3946])
    }

    /// Verifies that loadProductIDs properly relays Networking Layer errors.
    ///
    func test_loadProductIDs_properly_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        var result: Error?

        // When
        do {
            let _ = try await remote.loadProductIDs(for: self.sampleSiteID)
        } catch {
            result = error
        }

        // Then
        XCTAssertEqual(result as? NetworkError, NetworkError.notFound)
    }

    func test_create_template_product_returns_product_id() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "onboarding/tasks/create_product_from_template", filename: "product-id-only")

        // When
        let productID = try await remote.createTemplateProduct(for: self.sampleSiteID, template: .physical)

        // Then
        XCTAssertEqual(productID, 3946)
    }
}

// MARK: - Private Helpers
//
private extension ProductsRemoteTests {

    func sampleProduct() -> Product {
        return Product(siteID: sampleSiteID,
                       productID: sampleProductID,
                       name: "Book the Green Room",
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       date: DateFormatter.dateFromString(with: "2019-02-19T17:33:31"),
                       dateCreated: DateFormatter.dateFromString(with: "2019-02-19T17:33:31"),
                       dateModified: DateFormatter.dateFromString(with: "2019-02-19T17:48:01"),
                       dateOnSaleStart: DateFormatter.dateFromString(with: "2019-10-15T21:30:00"),
                       dateOnSaleEnd: DateFormatter.dateFromString(with: "2019-10-27T21:29:59"),
                       productTypeKey: "booking",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>This is the party room!</p>\n",
                       shortDescription: """
                           [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
                           We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let us \
                           know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests \
                           for $100.</p>\n
                           """,
                       sku: "",
                       price: "0",
                       regularPrice: "",
                       salePrice: "",
                       onSale: false,
                       purchasable: true,
                       totalSales: 0,
                       virtual: true,
                       downloadable: false,
                       downloads: [],
                       downloadLimit: -1,
                       downloadExpiry: -1,
                       buttonText: "",
                       externalURL: "http://somewhere.com",
                       taxStatusKey: "taxable",
                       taxClass: "",
                       manageStock: false,
                       stockQuantity: nil,
                       stockStatusKey: "instock",
                       backordersKey: "no",
                       backordersAllowed: false,
                       backordered: false,
                       soldIndividually: true,
                       weight: "213",
                       dimensions: sampleDimensions(),
                       shippingRequired: false,
                       shippingTaxable: false,
                       shippingClass: "",
                       shippingClassID: 0,
                       productShippingClass: nil,
                       reviewsAllowed: true,
                       averageRating: "4.30",
                       ratingCount: 23,
                       relatedIDs: [31, 22, 369, 414, 56],
                       upsellIDs: [99, 1234566],
                       crossSellIDs: [1234, 234234, 3],
                       parentID: 0,
                       purchaseNote: "Thank you!",
                       categories: sampleCategories(),
                       tags: sampleTags(),
                       images: sampleImages(),
                       attributes: sampleAttributes(),
                       defaultAttributes: sampleDefaultAttributes(),
                       variations: [192, 194, 193],
                       groupedProducts: [],
                       menuOrder: 0,
                       addOns: [])
    }

    func sampleDimensions() -> Networking.ProductDimensions {
        return ProductDimensions(length: "12", width: "33", height: "54")
    }

    func sampleCategories() -> [Networking.ProductCategory] {
        let category1 = ProductCategory(categoryID: 36, siteID: sampleSiteID, parentID: 0, name: "Events", slug: "events")
        return [category1]
    }

    func sampleTags() -> [Networking.ProductTag] {
        let tag1 = ProductTag(siteID: sampleSiteID, tagID: 37, name: "room", slug: "room")
        let tag2 = ProductTag(siteID: sampleSiteID, tagID: 38, name: "party room", slug: "party-room")
        let tag3 = ProductTag(siteID: sampleSiteID, tagID: 39, name: "30", slug: "30")
        let tag4 = ProductTag(siteID: sampleSiteID, tagID: 40, name: "20+", slug: "20")
        let tag5 = ProductTag(siteID: sampleSiteID, tagID: 41, name: "meeting room", slug: "meeting-room")
        let tag6 = ProductTag(siteID: sampleSiteID, tagID: 42, name: "meetings", slug: "meetings")
        let tag7 = ProductTag(siteID: sampleSiteID, tagID: 43, name: "parties", slug: "parties")
        let tag8 = ProductTag(siteID: sampleSiteID, tagID: 44, name: "graduation", slug: "graduation")
        let tag9 = ProductTag(siteID: sampleSiteID, tagID: 45, name: "birthday party", slug: "birthday-party")

        return [tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, tag9]
    }

    func sampleImages() -> [Networking.ProductImage] {
        let image1 = ProductImage(imageID: 19,
                                  dateCreated: DateFormatter.dateFromString(with: "2018-01-26T21:49:45"),
                                  dateModified: DateFormatter.dateFromString(with: "2018-01-26T21:50:11"),
                                  src: "https://somewebsite.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/01/vneck-tee.jpg.png",
                                  name: "Vneck Tshirt",
                                  alt: "")
        return [image1]
    }

    func sampleAttributes() -> [Networking.ProductAttribute] {
        let attribute1 = ProductAttribute(siteID: sampleSiteID,
                                          attributeID: 0,
                                          name: "Color",
                                          position: 1,
                                          visible: true,
                                          variation: true,
                                          options: ["Purple", "Yellow", "Hot Pink", "Lime Green", "Teal"])

        let attribute2 = ProductAttribute(siteID: sampleSiteID,
                                          attributeID: 0,
                                          name: "Size",
                                          position: 0,
                                          visible: true,
                                          variation: true,
                                          options: ["Small", "Medium", "Large"])

        return [attribute1, attribute2]
    }

    func sampleDefaultAttributes() -> [Networking.ProductDefaultAttribute] {
        let defaultAttribute1 = ProductDefaultAttribute(attributeID: 0, name: "Color", option: "Purple")
        let defaultAttribute2 = ProductDefaultAttribute(attributeID: 0, name: "Size", option: "Medium")

        return [defaultAttribute1, defaultAttribute2]
    }
}
