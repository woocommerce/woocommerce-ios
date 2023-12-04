import XCTest

@testable import Networking

final class ProductVariationsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Dummy Product ID
    ///
    let sampleProductID: Int64 = 173

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load all product variations tests

    /// Verifies that loadAllProductVariations properly parses the `product-variations-load-all` sample response.
    ///
    func testLoadAllProductVariationsProperlyReturnsParsedData() {
        let remote = ProductVariationsRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Variations")

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations", filename: "product-variations-load-all")

        remote.loadAllProductVariations(for: sampleSiteID,
                                        productID: sampleProductID,
                                        variationIDs: []) { productVariations, error in
            XCTAssertNil(error)
            XCTAssertNotNil(productVariations)
            XCTAssertEqual(productVariations?.count, 8)

            // Validates on Variation of ID 1275.
            let expectedVariationID: Int64 = 1275
            guard let expectedVariation = productVariations?.first(where: { $0.productVariationID == expectedVariationID }) else {
                XCTFail("Product variation with ID \(expectedVariationID) should exist")
                return
            }
            XCTAssertEqual(expectedVariation.description, "<p>Nutty chocolate marble, 99% and organic.</p>\n")
            XCTAssertEqual(expectedVariation.sku, "99%-nuts-marble")
            XCTAssertEqual(expectedVariation.permalink, "https://chocolate.com/marble")

            XCTAssertEqual(expectedVariation.dateCreated, DateFormatter.dateFromString(with: "2019-11-14T12:40:55"))
            XCTAssertEqual(expectedVariation.dateModified, DateFormatter.dateFromString(with: "2019-11-14T13:06:42"))
            XCTAssertEqual(expectedVariation.dateOnSaleStart, DateFormatter.dateFromString(with: "2019-10-15T21:30:00"))
            XCTAssertEqual(expectedVariation.dateOnSaleEnd, DateFormatter.dateFromString(with: "2019-10-27T21:29:59"))

            let expectedPrice = 12
            XCTAssertEqual(expectedVariation.price, "\(expectedPrice)")
            XCTAssertEqual(expectedVariation.regularPrice, "\(expectedPrice)")
            XCTAssertEqual(expectedVariation.salePrice, "8")

            XCTAssertEqual(expectedVariation.status, .published)
            XCTAssertEqual(expectedVariation.stockStatus, .inStock)

            let expectedAttributes: [ProductVariationAttribute] = [
                ProductVariationAttribute(id: 0, name: "Darkness", option: "99%"),
                ProductVariationAttribute(id: 0, name: "Flavor", option: "nuts"),
                ProductVariationAttribute(id: 0, name: "Shape", option: "marble")
            ]
            XCTAssertEqual(expectedVariation.attributes, expectedAttributes)

            XCTAssertEqual(expectedVariation.image?.imageID, 1063)

            XCTAssertFalse(expectedVariation.onSale)
            XCTAssertTrue(expectedVariation.purchasable)
            XCTAssertFalse(expectedVariation.virtual)
            XCTAssertTrue(expectedVariation.downloadable)

            XCTAssertTrue(expectedVariation.manageStock)
            XCTAssertEqual(expectedVariation.stockQuantity, 16.5)
            XCTAssertEqual(expectedVariation.backordersKey, "notify")
            XCTAssertTrue(expectedVariation.backordersAllowed)
            XCTAssertFalse(expectedVariation.backordered)

            XCTAssertEqual(expectedVariation.downloads.count, 0)
            XCTAssertEqual(expectedVariation.downloadLimit, -1)
            XCTAssertEqual(expectedVariation.downloadExpiry, 0)

            XCTAssertEqual(expectedVariation.taxStatusKey, "taxable")
            XCTAssertEqual(expectedVariation.taxClass, "")

            XCTAssertEqual(expectedVariation.weight, "2.5")
            XCTAssertEqual(expectedVariation.dimensions, ProductDimensions(length: "10", width: "2.5", height: ""))

            XCTAssertEqual(expectedVariation.shippingClass, "")
            XCTAssertEqual(expectedVariation.shippingClassID, 0)

            XCTAssertEqual(expectedVariation.menuOrder, 8)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAllProductVariations properly relays Networking Layer errors.
    ///
    func testLoadAllProductVariationsProperlyRelaysNetwokingErrors() {
        let remote = ProductVariationsRemote(network: network)
        let expectation = self.expectation(description: "Load All Product Variations returns error")

        remote.loadAllProductVariations(for: sampleSiteID,
                                        productID: sampleProductID,
                                        variationIDs: []) { (productVariations, error) in
            XCTAssertNil(productVariations)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_loadAllProductVariations_with_non_empty_variationIDs_adds_include_parameter() throws {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let includedVariationIDs: [Int64] = [17, 671]

        // When
        remote.loadAllProductVariations(for: sampleSiteID,
                                        productID: sampleProductID,
                                        variationIDs: includedVariationIDs) { _, _ in }

        // Then
        let queryParameters = try XCTUnwrap(network.queryParameters)
        let expectedParam = "include=17,671"
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    func test_loadAllProductVariations_with_empty_variationIDs_does_not_add_include_parameter() throws {
        // Given
        let remote = ProductVariationsRemote(network: network)

        // When
        remote.loadAllProductVariations(for: sampleSiteID,
                                        productID: sampleProductID,
                                        variationIDs: []) { _, _ in }

        // Then
        let queryParametersDictionary = try XCTUnwrap(network.queryParametersDictionary)
        XCTAssertFalse(queryParametersDictionary.contains(where: { $0.key == "include" }))
    }

    // MARK: - Load single product variation tests

    /// Verifies that loadProductVariation properly parses the `product-variation` sample response.
    ///
    func test_load_single_ProductVariation_returns_parsed_ProductVariation() throws {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let sampleProductVariationID: Int64 = 1275
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations/\(sampleProductVariationID)", filename: "product-variation")

        // When
        let result = waitFor { promise in
            remote.loadProductVariation(for: self.sampleSiteID, productID: self.sampleProductID, variationID: sampleProductVariationID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let productVariation = try result.get()
        XCTAssertEqual(productVariation.productID, sampleProductID)
        XCTAssertEqual(productVariation.productVariationID, sampleProductVariationID)
    }

    /// Verifies that loadProductVariation properly relays any Networking Layer errors.
    ///
    func test_load_single_ProductVariation_properly_relays_netwoking_errors() throws {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let sampleProductVariationID: Int64 = 2783

        // When
        let result = waitFor { promise in
            remote.loadProductVariation(for: self.sampleSiteID, productID: self.sampleProductID, variationID: sampleProductVariationID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .notFound())
    }

    // MARK: - Create ProductVariations in batch tests

    /// Verifies that createProductVariations properly parses the `product-variations-create-update-delete-in-batch` sample response.
    ///
    func test_createProductVariation_properly_returns_parsed_ProductVariation() throws {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let sampleProductVariationID: Int64 = 1275
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations", filename: "product-variation")

        let result = waitFor { promise in
            remote.createProductVariation(for: self.sampleSiteID,
                                          productID: self.sampleProductID,
                                          newVariation:
                                            self.sampleCreateProductVariation(siteID: self.sampleSiteID, productID: self.sampleProductID)) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let productVariationCreated = try result.get()
        XCTAssertEqual(productVariationCreated.productID, sampleProductID)
        XCTAssertEqual(productVariationCreated.productVariationID, sampleProductVariationID)
    }

    /// Verifies that createProductVariations properly relays Networking Layer errors.
    ///
    func test_createProductVariations_properly_relays_networking_errors() throws {
        // Given
        let remote = ProductVariationsRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.createProductVariation(for: self.sampleSiteID,
                                          productID: self.sampleProductID,
                                          newVariation:
                                            self.sampleCreateProductVariation(siteID: self.sampleSiteID, productID: self.sampleProductID)) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isFailure)
    }

    func test_create_product_variations_returns_parsed_variations() throws {
        // Given
        let remote = ProductVariationsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations/batch", filename: "product-variations-bulk-create")

        // When
        let result = waitFor { promise in
            remote.createProductVariations(siteID: self.sampleSiteID, productID: self.sampleProductID, productVariations: []) { result in
                promise(result)
            }
        }

        // Then
        let sampleProductVariationID: Int64 = 2783
        let expectedVariations = [sampleProductVariation(siteID: sampleSiteID, productID: sampleProductID, id: sampleProductVariationID)]
        let createdVariations = try result.get()
        XCTAssertEqual(createdVariations, expectedVariations)
    }

    // MARK: - Update ProductVariation

    /// Verifies that updateProductVariation properly parses the `product-variation-update` sample response.
    ///
    func testUpdateProductVariationProperlyReturnsParsedProduct() {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let sampleProductVariationID: Int64 = 2783
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations/\(sampleProductVariationID)", filename: "product-variation-update")
        let productVariation = sampleProductVariation(siteID: sampleSiteID, productID: sampleProductID, id: sampleProductVariationID)

        // When
        var updatedProductVariation: ProductVariation?
        waitForExpectation { expectation in
            remote.updateProductVariation(productVariation: productVariation) { result in
                updatedProductVariation = try? result.get()
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertEqual(updatedProductVariation, productVariation)
    }

    /// Verifies that updateProductVariations properly parses the `product-variations-bulk-update` sample response.
    ///
    func test_bulk_update_productVariations_properly_returns_parsed_products() {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let sampleProductVariationID: Int64 = 2783

        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations/batch", filename: "product-variations-bulk-update")
        let productVariations = [sampleProductVariation(siteID: sampleSiteID, productID: sampleProductID, id: sampleProductVariationID)]

        // When
        var updatedProductVariation: [ProductVariation]?
        waitForExpectation { expectation in
            remote.updateProductVariations(siteID: sampleSiteID, productID: sampleProductID, productVariations: productVariations) { result in
                updatedProductVariation = try? result.get()
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertEqual(updatedProductVariation, productVariations)
    }

    /// Verifies that updateProductVariation properly relays Networking Layer errors.
    ///
    func testUpdateProductVariationProperlyRelaysNetwokingErrors() {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let sampleProductVariationID: Int64 = 2783
        let productVariation = sampleProductVariation(siteID: sampleSiteID, productID: sampleProductID, id: sampleProductVariationID)

        // When
        var result: Result<ProductVariation, Error>?
        waitForExpectation { expectation in
            remote.updateProductVariation(productVariation: productVariation) { updatedResult in
                result = updatedResult
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isFailure)
    }

    /// Verifies that `updateProductVariationImage` properly parses the `product-variation-update` sample response.
    ///
    func test_updateProductVariationImage_properly_returns_parsed_product() throws {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let sampleProductVariationID: Int64 = 2783
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations/\(sampleProductVariationID)", filename: "product-variation-update")

        // When
        let result = waitFor { promise in
            remote.updateProductVariationImage(siteID: self.sampleSiteID,
                                               productID: self.sampleProductID,
                                               variationID: sampleProductVariationID,
                                               image: .fake()) { result in
                promise(result)
            }
        }

        // Then
        let productVariation = try XCTUnwrap(result.get())
        XCTAssertEqual(productVariation.image?.imageID, 2432)
    }

    /// Verifies that `updateProductVariationImage` properly relays Networking Layer errors.
    ///
    func test_updateProductVariationImage_properly_relays_networking_error() throws {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let sampleProductVariationID: Int64 = 2783

        // When
        let result = waitFor { promise in
            remote.updateProductVariationImage(siteID: self.sampleSiteID,
                                               productID: self.sampleProductID,
                                               variationID: sampleProductVariationID,
                                               image: .fake()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - Delete ProductVariation

    /// Verifies that deleteProductVariation properly parses the `product-variation` sample response.
    ///
    func test_deleteProductVariation_properly_returns_parsed_ProductVariation() throws {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let sampleProductVariationID: Int64 = 1275
        network.simulateResponse(requestUrlSuffix: "products/\(sampleProductID)/variations/\(sampleProductVariationID)", filename: "product-variation")

        // When
        let result = waitFor { promise in
            remote.deleteProductVariation(siteID: self.sampleSiteID,
                                          productID: self.sampleProductID,
                                          variationID: sampleProductVariationID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let productVariation = try result.get()
        XCTAssertEqual(productVariation.productID, sampleProductID)
        XCTAssertEqual(productVariation.productVariationID, sampleProductVariationID)
    }

    /// Verifies that deleteProductVariation properly relays Networking Layer errors.
    ///
    func test_deleteProductVariation_properly_relays_networking_errors() {
        // Given
        let remote = ProductVariationsRemote(network: network)
        let sampleProductVariationID: Int64 = 1275

        // When
        let result = waitFor { promise in
            remote.deleteProductVariation(siteID: self.sampleSiteID,
                                          productID: self.sampleProductID,
                                          variationID: sampleProductVariationID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}

private extension ProductVariationsRemoteTests {
    func sampleProductVariation(siteID: Int64,
                                productID: Int64,
                                id: Int64) -> ProductVariation {
        let imageSource = "https://i0.wp.com/funtestingusa.wpcomstaging.com/wp-content/uploads/2019/11/img_0002-1.jpeg?fit=4288%2C2848&ssl=1"
        return ProductVariation(siteID: siteID,
                                productID: productID,
                                productVariationID: id,
                                attributes: sampleProductVariationAttributes(),
                                image: ProductImage(imageID: 2432,
                                                    dateCreated: DateFormatter.dateFromString(with: "2020-03-13T03:13:57"),
                                                    dateModified: DateFormatter.dateFromString(with: "2020-07-21T08:29:16"),
                                                    src: imageSource,
                                                    name: "DSC_0010",
                                                    alt: ""),
                                permalink: "https://chocolate.com/marble",
                                dateCreated: DateFormatter.dateFromString(with: "2020-06-12T14:36:02"),
                                dateModified: DateFormatter.dateFromString(with: "2020-07-21T08:35:47"),
                                dateOnSaleStart: nil,
                                dateOnSaleEnd: nil,
                                status: .published,
                                description: "<p>Nutty chocolate marble, 99% and organic.</p>\n",
                                sku: "87%-strawberry-marble",
                                price: "14.99",
                                regularPrice: "14.99",
                                salePrice: "",
                                onSale: false,
                                purchasable: true,
                                virtual: false,
                                downloadable: true,
                                downloads: [],
                                downloadLimit: -1,
                                downloadExpiry: 0,
                                taxStatusKey: "taxable",
                                taxClass: "",
                                manageStock: false,
                                stockQuantity: 16,
                                stockStatus: .inStock,
                                backordersKey: "notify",
                                backordersAllowed: true,
                                backordered: false,
                                weight: "2.5",
                                dimensions: ProductDimensions(length: "10",
                                                              width: "2.5",
                                                              height: ""),
                                shippingClass: "",
                                shippingClassID: 0,
                                menuOrder: 1,
                                subscription: nil,
                                minAllowedQuantity: nil,
                                maxAllowedQuantity: nil,
                                groupOfQuantity: nil,
                                overrideProductQuantities: nil)
    }

    func sampleProductVariationAttributes() -> [ProductVariationAttribute] {
        return [
            ProductVariationAttribute(id: 0, name: "Darkness", option: "87%"),
            ProductVariationAttribute(id: 0, name: "Flavor", option: "strawberry"),
            ProductVariationAttribute(id: 0, name: "Shape", option: "marble")
        ]
    }

    func sampleCreateProductVariation(siteID: Int64,
                                      productID: Int64,
                                      subscription: ProductSubscription? = nil) -> CreateProductVariation {
        let createVariation = CreateProductVariation(regularPrice: "5.0",
                                                     salePrice: "4.5",
                                                     attributes: sampleProductVariationAttributes(),
                                                     description: "",
                                                     image: .fake(),
                                                     subscription: subscription)
        return createVariation
    }
}
