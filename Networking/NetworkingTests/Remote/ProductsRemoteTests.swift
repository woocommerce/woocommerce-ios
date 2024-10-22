import TestKit
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

    func test_addProduct_with_success_mock_returns_a_product() {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "product-add-or-delete")

        // When
        let product = sampleProduct()
        var addedProduct: Product?
        waitForExpectation { expectation in
            remote.addProduct(product: product) { result in
                addedProduct = try? result.get()
                expectation.fulfill()
            }
        }

        // Then
        let expectedProduct = Product.fake().copy(siteID: sampleSiteID,
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
                                      addOns: [],
                                      isSampleItem: false,
                                      bundleStockStatus: nil,
                                      bundleStockQuantity: nil,
                                      bundledItems: [],
                                      password: nil,
                                      compositeComponents: [],
                                      subscription: nil,
                                      minAllowedQuantity: nil,
                                      maxAllowedQuantity: nil,
                                      groupOfQuantity: nil,
                                      combineVariationQuantities: nil)
        XCTAssertEqual(addedProduct, expectedProduct)
    }

    func test_addProduct_relays_networking_error() {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        let product = sampleProduct()
        var result: Result<Product, Error>?
        waitForExpectation { expectation in
            remote.addProduct(product: product) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertEqual(result?.isFailure, true)
    }

    // MARK: - Delete Product

    func test_deleteProduct_with_success_mock_returns_a_product() {
        // Given
        let remote = ProductsRemote(network: network)

        /// When we delete a product, it return the deleted product.
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-add-or-delete")

        // When
        var deletedProduct: Product?
        waitForExpectation { expectation in
            remote.deleteProduct(for: sampleSiteID, productID: sampleProductID) { (result) in
                deletedProduct = try? result.get()
                expectation.fulfill()
            }
        }

        // Then
        let expectedProduct = Product.fake().copy(siteID: sampleSiteID,
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
                                      addOns: [],
                                      isSampleItem: false,
                                      bundleStockStatus: nil,
                                      bundleStockQuantity: nil,
                                      bundledItems: [],
                                      password: nil,
                                      compositeComponents: [],
                                      subscription: nil,
                                      minAllowedQuantity: nil,
                                      maxAllowedQuantity: nil,
                                      groupOfQuantity: nil,
                                      combineVariationQuantities: nil)
        XCTAssertEqual(deletedProduct, expectedProduct)
    }

    func test_deleteProduct_relays_networking_error() {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        var result: Result<Product, Error>?
        waitForExpectation { expectation in
            remote.deleteProduct(for: sampleSiteID, productID: sampleProductID) { (aResult) in
                result = aResult
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertEqual(result?.isFailure, true)
    }

    // MARK: - Load all products tests

    /// Verifies that loadAllProducts properly parses the `products-load-all` sample response.
    ///
    func testLoadAllProductsProperlyReturnsParsedProducts() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load All Products")

        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")

        remote.loadAllProducts(for: sampleSiteID) { result in
            switch result {
            case .success(let products):
                XCTAssertEqual(products.count, 10)
            default:
                XCTFail("Unexpected result: \(result)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAllProducts with `excludedProductIDs` makes a network request with the corresponding parameter.
    ///
    func testLoadAllProductsWithExcludedIDsIncludesAnExcludeParamInNetworkRequest() throws {
        // Arrange
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        let excludedProductIDs: [Int64] = [17, 671]

        // Action
        waitForExpectation { expectation in
            remote.loadAllProducts(for: sampleSiteID, excludedProductIDs: excludedProductIDs) { result in
                expectation.fulfill()
            }
        }

        // Assert
        let queryParameters = try XCTUnwrap(network.queryParameters)
        let expectedParam = "exclude=17,671"
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    /// Verifies that loadAllProducts with `productIDs` makes a network request with the `include` parameter.
    ///
    func test_loadAllProducts_with_productIDs_adds_a_include_param_in_network_request() throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")
        let productIDs: [Int64] = [13, 61]

        // When
        waitForExpectation { expectation in
            remote.loadAllProducts(for: sampleSiteID, productIDs: productIDs) { result in
                expectation.fulfill()
            }
        }

        // Then
        let queryParameters = try XCTUnwrap(network.queryParameters)
        let expectedParam = "include=13,61"
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    /// Verifies that loadAllProducts with empty `productIDs` makes a network request without the `include` parameter.
    ///
    func test_loadAllProducts_with_empty_productIDs_does_not_add_include_param_in_network_request() throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all")

        // When
        waitForExpectation { expectation in
            remote.loadAllProducts(for: sampleSiteID, productIDs: []) { result in
                expectation.fulfill()
            }
        }

        // Then
        let queryParameters = try XCTUnwrap(network.queryParameters)
        let includeParam = "include"
        XCTAssertFalse(queryParameters.contains(includeParam), "`include` param should not be present")
    }

    /// Verifies that loadAllProducts properly relays Networking Layer errors.
    ///
    func test_loadAllProducts_properly_relays_netwoking_errors() {
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load all products returns error")

        remote.loadAllProducts(for: sampleSiteID) { result in
            switch result {
            case .failure:
                break
            default:
                XCTFail("Unexpected result: \(result)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - Load single product tests

    /// Verifies that loadProduct properly parses the `product` sample response.
    ///
    func test_loadSingleProduct_properly_returns_parsed_product() throws {
        // Given
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load single product")

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product")

        // When
        var resultMaybe: Result<Product, Error>?
        remote.loadProduct(for: sampleSiteID, productID: sampleProductID) { aResult in
            resultMaybe = aResult
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then
        let result = try XCTUnwrap(resultMaybe)
        XCTAssertTrue(result.isSuccess)

        let product = try result.get()
        XCTAssertEqual(product.productID, sampleProductID)
    }

    /// Verifies that loadProduct properly parses the `product-external` sample response.
    ///
    func test_loadSingleExternalProduct_properly_returns_parsed_product() throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-external")

        // When
        var resultMaybe: Result<Product, Error>?
        waitForExpectation { expectation in
            remote.loadProduct(for: sampleSiteID, productID: sampleProductID) { aResult in
                resultMaybe = aResult
                expectation.fulfill()
            }
        }

        // Then
        let result = try XCTUnwrap(resultMaybe)
        XCTAssertTrue(result.isSuccess)

        let product = try result.get()
        XCTAssertEqual(product.productID, sampleProductID)
        XCTAssertEqual(product.buttonText, "Hit the slopes")
        XCTAssertEqual(product.externalURL, "https://snowboarding.com/product/rentals/")
    }

    /// Verifies that loadProduct properly relays any Networking Layer errors.
    ///
    func test_loadSingleProduct_properly_relays_netwoking_errors() throws {
        // Given
        let remote = ProductsRemote(network: network)
        let expectation = self.expectation(description: "Load single product returns error")

        // When
        var resultMaybe: Result<Product, Error>?
        remote.loadProduct(for: sampleSiteID, productID: sampleProductID) { aResult in
            resultMaybe = aResult
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then
        let result = try XCTUnwrap(resultMaybe)
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - Search Products

    /// Verifies that searchProducts properly parses the `products-load-all` sample response.
    ///
    func test_searchProducts_properly_returns_parsed_products() throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-search-photo")

        // When
        let result: Result<[Product], Error> = waitFor { promise in
            remote.searchProducts(for: self.sampleSiteID,
                                  keyword: "photo",
                                  pageNumber: 0,
                                  pageSize: 100) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let products = try result.get()
        XCTAssertEqual(products.count, 2)
    }

    /// Verifies that searchProducts properly relays Networking Layer errors.
    ///
    func test_searchProducts_properly_relays_networking_errors() {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        let result: Result<[Product], Error> = waitFor { promise in
            remote.searchProducts(for: self.sampleSiteID,
                                  keyword: String(),
                                  pageNumber: 0,
                                  pageSize: 100) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - Search Products by SKU

    func test_searchProductsBySKU_properly_returns_parsed_products() throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-sku-search")

        // When
        let result: Result<[Product], Error> = waitFor { promise in
            remote.searchProductsBySKU(for: self.sampleSiteID,
                                       keyword: "choco",
                                       pageNumber: 0,
                                       pageSize: 100) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let products = try result.get()
        XCTAssertEqual(products.count, 1)
    }

    func test_searchProductsBySKU_properly_relays_networking_errors() {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        let result: Result<[Product], Error> = waitFor { promise in
            remote.searchProductsBySKU(for: self.sampleSiteID,
                                       keyword: String(),
                                       pageNumber: 0,
                                       pageSize: 100) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }


    // MARK: - Search Product SKU tests

    /// Verifies that searchSku properly parses the product `sku` sample response.
    ///
    func test_searchSku_properly_returns_parsed_sku() throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "product-search-sku")
        let expectedSku = "T-SHIRT-HAPPY-NINJA"

        // When
        let result: Result<String, Error> = waitFor { promise in
            remote.searchSku(for: self.sampleSiteID, sku: expectedSku) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let sku = try result.get()
        XCTAssertEqual(sku, expectedSku)
    }

    /// Verifies that searchSku properly relays Networking Layer errors.
    ///
    func test_searchSku_properly_relays_netwoking_errors() {
        // Given
        let remote = ProductsRemote(network: network)
        let skuToSearch = "T-SHIRT-HAPPY-NINJA"

        // When
        let result: Result<String, Error> = waitFor { promise in
            remote.searchSku(for: self.sampleSiteID, sku: skuToSearch) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }


    // MARK: - Update Product

    /// Verifies that updateProduct properly parses the `product-update` sample response.
    ///
    func test_updateProduct_properly_returns_parsed_product() {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-update")

        let productName = "This is my new product name!"
        let productDescription = "Learn something!"

        // When
        let product = sampleProduct()
        waitForExpectation { expectation in
            remote.updateProduct(product: product) { result in
                // Then
                guard case let .success(product) = result else {
                    XCTFail("Unexpected result: \(result)")
                    return
                }
                XCTAssertEqual(product.name, productName)
                XCTAssertEqual(product.fullDescription, productDescription)
                expectation.fulfill()
            }
        }
    }

    /// Verifies that updateProduct properly relays Networking Layer errors.
    ///
    func test_updateProduct_properly_relays_netwoking_errors() {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        let product = sampleProduct()
        waitForExpectation { expectation in
            remote.updateProduct(product: product) { result in
                // Then
                guard case .failure = result else {
                    XCTFail("Unexpected result: \(result)")
                    return
                }
                expectation.fulfill()
            }
        }
    }

    // MARK: - Update Product Images

    /// Verifies that updateProductImages properly parses the `product-update` sample response.
    ///
    func test_updateProductImages_properly_returns_parsed_product() throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)", filename: "product-update")

        // When
        let result = waitFor { promise in
            remote.updateProductImages(siteID: self.sampleSiteID, productID: self.sampleProductID, images: []) { result in
                promise(result)
            }
        }

        // Then
        let product = try XCTUnwrap(result.get())
        XCTAssertEqual(product.images.map { $0.imageID }, [1043, 1064])
    }

    /// Verifies that updateProductImages properly relays Networking Layer errors.
    ///
    func test_updateProductImages_properly_relays_networking_error() {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.updateProductImages(siteID: self.sampleSiteID, productID: self.sampleProductID, images: []) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - Products batch update

    /// Verifies that updateProducts properly parses the `products-batch-update` sample response.
    ///
    func test_bulk_update_products_properly_returns_parsed_products() {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/batch", filename: "products-batch-update")

        // When
        let sampleProducts = [sampleProduct()]
        let updatedProducts = waitFor { promise in
            remote.updateProducts(siteID: self.sampleSiteID, products: sampleProducts) { result in
                // Then
                guard case let .success(products) = result else {
                    XCTFail("Unexpected result: \(result)")
                    return
                }
                promise(products)
            }
        }

        // Then
        assertEqual(updatedProducts, sampleProducts)
    }

    // MARK: - Product IDs

    /// Verifies that loadProductIDs properly parses the `products-ids-only` sample response.
    ///
    func test_loadProductIDs_properly_returns_parsed_ids() throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-ids-only")

        // When
        let result = waitFor { promise in
            remote.loadProductIDs(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let productIDs = try XCTUnwrap(result.get())
        XCTAssertEqual(productIDs, [3946])
    }

    /// Verifies that loadProductIDs properly relays Networking Layer errors.
    ///
    func test_loadProductIDs_properly_relays_networking_error() {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.loadProductIDs(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    func test_loadProductIDs_removes_status_parameter_when_empty() throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-ids-only")

        // When
        waitForExpectation { expectation in
            remote.loadProductIDs(for: sampleSiteID) { result in
                expectation.fulfill()
            }
        }

        // Assert
        let queryParameters = try XCTUnwrap(network.queryParameters)
        let emptyParam = "status="
        XCTAssertFalse(queryParameters.contains(emptyParam), "Unexpected empty query param: \(emptyParam)")
    }

    // MARK: - `loadNumberOfProducts`

    func test_loadNumberOfProducts_returns_sum_of_all_product_types() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/products/totals", filename: "products-total")

        // When
        let numberOfProducts = try await remote.loadNumberOfProducts(siteID: 7)

        // Then
        XCTAssertEqual(numberOfProducts, 124)
    }

    func test_loadNumberOfProducts_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        await assertThrowsError({ _ = try await remote.loadNumberOfProducts(siteID: 7) },
                                errorAssert: {
            // Then
            $0 as? NetworkError == .notFound()
        })
    }

    // MARK: - `loadStock`

    func test_loadStock_returns_correct_items() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/stock", filename: "product-stock")

        // When
        let stock = try await remote.loadStock(for: 8, with: "outOfStock", pageNumber: 1, pageSize: 3, order: .descending)

        // Then
        XCTAssertEqual(stock.count, 1)

        let item = try XCTUnwrap(stock.first)
        XCTAssertEqual(item.productID, 2051)
        XCTAssertEqual(item.name, "貴志川線 1日乘車券")
        XCTAssertEqual(item.sku, "")
        XCTAssertEqual(item.productStockStatus, .outOfStock)
        XCTAssertEqual(item.stockQuantity, 0)
        XCTAssertFalse(item.manageStock)
    }

    func test_loadStock_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        await assertThrowsError({ _ = try await remote.loadStock(for: 8, with: "outofstock", pageNumber: 1, pageSize: 3, order: .descending) },
                                errorAssert: {
            // Then
            $0 as? NetworkError == .notFound()
        })
    }

    // MARK: - Load product reports

    func test_loadProductReports_returns_correct_items() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/products", filename: "product-report")

        // When
        let products = try await remote.loadProductReports(for: sampleSiteID,
                                                           productIDs: [119, 134],
                                                           timeZone: .gmt,
                                                           earliestDateToInclude: Date(timeIntervalSinceNow: -3600*24*7),
                                                           latestDateToInclude: Date(),
                                                           pageSize: 3,
                                                           pageNumber: 1,
                                                           orderBy: .itemsSold,
                                                           order: .descending)

        // Then
        XCTAssertEqual(products.count, 1)

        let firstItem = try XCTUnwrap(products.first)
        XCTAssertEqual(firstItem.productID, 248)
        XCTAssertEqual(firstItem.name, "Fantastic Concrete Shirt")
        XCTAssertEqual(firstItem.itemsSold, 8)
        XCTAssertEqual(firstItem.stockQuantity, 24)
        XCTAssertEqual(firstItem.imageURL?.absoluteString, "https://test.ninja/wp-content/uploads/2024/05/img-laboriosam-300x300.png")
    }

    func test_loadProductReports_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        await assertThrowsError({
            _ = try await remote.loadProductReports(for: sampleSiteID,
                                                    productIDs: [119, 134],
                                                    timeZone: .gmt,
                                                    earliestDateToInclude: Date(timeIntervalSinceNow: -3600*24*7),
                                                    latestDateToInclude: Date(),
                                                    pageSize: 3,
                                                    pageNumber: 1,
                                                    orderBy: .itemsSold,
                                                    order: .descending)
        }, errorAssert: {
            // Then
            $0 as? NetworkError == .notFound()
        })
    }

    // MARK: - Load variation reports

    func test_loadVariationReports_returns_correct_items() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/variations", filename: "variation-report")

        // When
        let products = try await remote.loadVariationReports(for: sampleSiteID,
                                                             productIDs: [119],
                                                             variationIDs: [120, 122],
                                                             timeZone: .gmt,
                                                             earliestDateToInclude: Date(timeIntervalSinceNow: -3600*24*7),
                                                             latestDateToInclude: Date(),
                                                             pageSize: 3,
                                                             pageNumber: 1,
                                                             orderBy: .itemsSold,
                                                             order: .descending)

        // Then
        XCTAssertEqual(products.count, 1)

        let firstItem = try XCTUnwrap(products.first)
        XCTAssertEqual(firstItem.productID, 248)
        XCTAssertEqual(firstItem.variationID, 280)
        XCTAssertEqual(firstItem.name, "Fantastic Concrete Shirt")
        XCTAssertEqual(firstItem.itemsSold, 8)
        XCTAssertEqual(firstItem.imageURL?.absoluteString, "https://test.ninja/wp-content/uploads/2024/05/img-laboriosam-300x300.png")
    }

    func test_loadVariationReports_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        await assertThrowsError({
            _ = try await remote.loadVariationReports(for: sampleSiteID,
                                                      productIDs: [119],
                                                      variationIDs: [120, 122],
                                                      timeZone: .gmt,
                                                      earliestDateToInclude: Date(timeIntervalSinceNow: -3600*24*7),
                                                      latestDateToInclude: Date(),
                                                      pageSize: 3,
                                                      pageNumber: 1,
                                                      orderBy: .itemsSold,
                                                      order: .descending)
        }, errorAssert: {
            // Then
            $0 as? NetworkError == .notFound()
        })
    }

    func test_loadAllSimpleProductsForPointOfSale_loads_simple_products() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let expectedProductsFromResponse = 6

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all-type-simple")

        let products = try await remote.loadSimpleProductsForPointOfSale(for: sampleSiteID)

        // Then
        XCTAssertEqual(products.count, expectedProductsFromResponse)
        for product in products {
            XCTAssertEqual(try XCTUnwrap(product).productType, .simple)
        }
    }

    func test_loadAllSimpleProductsForPointOfSale_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When/Then
        await assertThrowsError({
            let _ = try await remote.loadSimpleProductsForPointOfSale(for: sampleSiteID)
        }, errorAssert: {
            $0 as? NetworkError == .notFound()
        })
    }

    func test_loadAllSimpleProductsForPointOfSale_when_page_has_products_then_loads_expected_products() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let initialPageNumber = 1
        let expectedProductsFromResponse = 6

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all-type-simple")

        let products = try await remote.loadSimpleProductsForPointOfSale(for: sampleSiteID, pageNumber: initialPageNumber)

        // Then
        XCTAssertEqual(products.count, expectedProductsFromResponse)
        for product in products {
            XCTAssertEqual(try XCTUnwrap(product).productType, .simple)
        }
    }

    func test_loadAllSimpleProductsForPointOfSale_when_page_has_no_products_then_loads_expected_products() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let pageNumber = 2
        let expectedProductsFromResponse = 0

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        let products = try await remote.loadSimpleProductsForPointOfSale(for: sampleSiteID, pageNumber: pageNumber)

        // Then
        XCTAssertEqual(products.count, expectedProductsFromResponse)
    }
}

// MARK: - Private Helpers
//
private extension ProductsRemoteTests {

    func sampleProduct() -> Product {
        Product.fake().copy(siteID: sampleSiteID,
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
                       addOns: [],
                       isSampleItem: false,
                       bundleStockStatus: .inStock,
                       bundleStockQuantity: nil,
                       bundledItems: [],
                       compositeComponents: [],
                       subscription: nil,
                       minAllowedQuantity: nil,
                       maxAllowedQuantity: nil,
                       groupOfQuantity: nil,
                       combineVariationQuantities: nil)
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
