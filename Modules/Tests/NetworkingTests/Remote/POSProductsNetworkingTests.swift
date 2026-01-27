import Testing
@testable import Networking
@testable import NetworkingCore

struct POSProductsNetworkingTests {

    let network = MockNetwork()
    let sampleSiteID: Int64 = 1234

    @Test func loadProductsForPointOfSale_loads_simple_products() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let expectedProductsFromResponse = 6

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all-type-simple")

        let pagedProducts = try await remote.loadProductsForPointOfSale(for: sampleSiteID)

        // Then
        let products = pagedProducts.items
        #expect(products.count == expectedProductsFromResponse)

        for product in products {
            #expect(product.productType == .simple)
        }
    }

    @Test func loadProductsForPointOfSale_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.loadProductsForPointOfSale(for: sampleSiteID)
        }
    }

    @Test func loadProductsForPointOfSale_when_page_has_products_then_loads_expected_products() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let initialPageNumber = 1
        let expectedProductsFromResponse = 6

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all-type-simple")

        let pagedProducts = try await remote.loadProductsForPointOfSale(for: sampleSiteID, pageNumber: initialPageNumber)

        // Then
        let products = pagedProducts.items
        #expect(products.count == expectedProductsFromResponse)

        for product in products {
            #expect(product.productType == .simple)
        }
    }

    @Test func loadProductsForPointOfSale_sets_correct_parameters() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.loadProductsForPointOfSale(for: sampleSiteID, productTypes: [.simple, .variable], pageNumber: 1)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["downloadable"] as? String == "false")
        #expect(queryParametersDictionary["include_types"] as? String == "simple,variable")
    }

    @Test(arguments: 1...4) func loadProductsForPointOfSale_returns_hasMorePages_based_on_header_with_case_insensitive_name(pageNumber: Int) async throws {
        // Given a response with 5 pages
        let remote = ProductsRemote(network: network)
        network.responseHeaders = ["X-WP-TotalPages": "5"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When loading page 1 to 4
        let pagedProducts = try await remote.loadProductsForPointOfSale(
            for: sampleSiteID,
            pageNumber: pageNumber)

        // Then there are more pages
        #expect(pagedProducts.hasMorePages == true)
    }

    @Test(arguments: [5, 6]) func loadProductsForPointOfSale_returns_false_for_hasMorePages_based_on_header(pageNumber: Int) async throws {
        // Given a response with 5 pages
        let remote = ProductsRemote(network: network)
        network.responseHeaders = ["X-WP-TotalPages": "5"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When loading page 5 or above
        let pagedProducts = try await remote.loadProductsForPointOfSale(
            for: sampleSiteID,
            pageNumber: pageNumber)

        // Then there are no more pages
        #expect(pagedProducts.hasMorePages == false)
    }

    @Test(arguments: 1...10) func loadProductsForPointOfSale_returns_hasMorePages_true_when_header_is_not_set(pageNumber: Int) async throws {
        // Given a response with nothing in it, but no X-WP-TotalPages header
        let remote = ProductsRemote(network: network)
        network.responseHeaders = nil
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When loading page
        let pagedProducts = try await remote.loadProductsForPointOfSale(
            for: sampleSiteID,
            pageNumber: pageNumber)

        // Then we assume there are still more pages
        #expect(pagedProducts.hasMorePages == true)
    }

    @Test func searchProductsForPointOfSale_sets_correct_parameters() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.searchProductsForPointOfSale(
            for: sampleSiteID,
            query: "search terms",
            productTypes: [.simple, .variable],
            pageNumber: 1)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["downloadable"] as? String == "false")
        #expect(queryParametersDictionary["include_types"] as? String == "simple,variable")
        #expect(queryParametersDictionary["search"] as? String == "search terms")
    }

    @Test func searchProductsForPointOfSale_sets_all_search_parameters() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let searchQuery = "search terms"

        // When
        _ = try? await remote.searchProductsForPointOfSale(
            for: sampleSiteID,
            query: searchQuery,
            productTypes: [.simple],
            pageNumber: 1)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["search"] as? String == searchQuery)
        #expect(queryParametersDictionary["search_name_or_sku"] as? String == searchQuery)
        #expect(queryParametersDictionary["search_fields"] as? [String] == ["name", "sku", "global_unique_id"])
    }

    @Test func searchProductsForPointOfSale_returns_parsed_products() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let expectedProductsFromResponse = 2

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-search-photo")

        let pagedProducts = try await remote.searchProductsForPointOfSale(
            for: sampleSiteID,
            query: "photo")

        // Then
        let products = pagedProducts.items
        #expect(products.count == expectedProductsFromResponse)
    }

    @Test func searchProductsForPointOfSale_relays_networking_error() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.searchProductsForPointOfSale(for: sampleSiteID, query: "search")
        }
    }

    @Test func posProduct_provides_field_names_for_request() {
        let fieldNames = POSProduct.requestFields
        #expect(fieldNames.contains("id"))
        #expect(fieldNames.contains("name"))
        #expect(fieldNames.contains("type"))
        #expect(fieldNames.contains("description"))
        #expect(fieldNames.contains("short_description"))
        #expect(fieldNames.contains("sku"))
        #expect(fieldNames.contains("global_unique_id"))
        #expect(fieldNames.contains("price"))
        #expect(fieldNames.contains("downloadable"))
        #expect(fieldNames.contains("parent_id"))
        #expect(fieldNames.contains("images"))
        #expect(fieldNames.contains("attributes"))
        #expect(fieldNames.contains("manage_stock"))
        #expect(fieldNames.contains("stock_quantity"))
        #expect(fieldNames.contains("stock_status"))
    }

    @Test func loadProductsForPointOfSale_requests_only_required_fields() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.loadProductsForPointOfSale(for: sampleSiteID)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["_fields"] as? String == POSProduct.requestFields.joined(separator: ","))
    }

    @Test func searchProductsForPointOfSale_requests_only_required_fields() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.searchProductsForPointOfSale(for: sampleSiteID, query: "search")

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["_fields"] as? String == POSProduct.requestFields.joined(separator: ","))
    }

    @Test func loadProductsForPointOfSale_returns_total_items_from_header() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let expectedTotalItems = 25
        network.responseHeaders = ["X-WP-Total": "\(expectedTotalItems)"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all-type-simple")

        // When
        let pagedProducts = try await remote.loadProductsForPointOfSale(for: sampleSiteID)

        // Then
        #expect(pagedProducts.totalItems == expectedTotalItems)
    }

    @Test func searchProductsForPointOfSale_returns_total_items_from_header() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let expectedTotalItems = 10
        network.responseHeaders = ["X-WP-Total": "\(expectedTotalItems)"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-search-photo")

        // When
        let pagedProducts = try await remote.searchProductsForPointOfSale(
            for: sampleSiteID,
            query: "photo")

        // Then
        #expect(pagedProducts.totalItems == expectedTotalItems)
    }

    @Test func loadProductsForPointOfSale_returns_nil_total_items_when_header_missing() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.responseHeaders = nil
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all-type-simple")

        // When
        let pagedProducts = try await remote.loadProductsForPointOfSale(for: sampleSiteID)

        // Then
        #expect(pagedProducts.totalItems == nil)
    }

    @Test func loadPOSProductByGlobalUniqueIdentifier_returns_single_product() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        let globalUniqueID = "123456789"

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "pos-products")
        _ = try await remote.loadPOSProductByGlobalUniqueIdentifier(for: sampleSiteID, globalUniqueID: globalUniqueID)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.method == .get)
        #expect(request.path == "products")
        #expect(request.parameters["global_unique_id"] as? String == globalUniqueID)
        #expect(request.parameters["page"] as? String == "1")
        #expect(request.parameters["per_page"] as? String == "1")
        #expect(request.parameters["context"] as? String == "edit")
        #expect(request.parameters["_fields"] as? String == POSProduct.requestFields.joined(separator: ","))
    }

    @Test func loadProductsForPointOfSale_includes_posProductsOnly_false_when_default() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        _ = try? await remote.loadProductsForPointOfSale(for: sampleSiteID,
                                                         productTypes: [.simple],
                                                         pageNumber: 1,
                                                         posProductsOnly: false)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["pos_products_only"] as? String == "false")
    }

    @Test func loadProductsForPointOfSale_includes_posProductsOnly_when_true() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.loadProductsForPointOfSale(for: sampleSiteID,
                                                         productTypes: [.simple],
                                                         pageNumber: 1,
                                                         posProductsOnly: true)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["pos_products_only"] as? String == "true")
    }

    @Test func loadPopularProductsForPointOfSale_includes_posProductsOnly_false_when_false() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.loadPopularProductsForPointOfSale(for: sampleSiteID,
                                                                 productTypes: [.simple],
                                                                 pageNumber: 1,
                                                                 perPage: 25,
                                                                 posProductsOnly: false)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["pos_products_only"] as? String == "false")
    }

    @Test func loadPopularProductsForPointOfSale_includes_posProductsOnly_when_true() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.loadPopularProductsForPointOfSale(for: sampleSiteID,
                                                                 productTypes: [.simple],
                                                                 pageNumber: 1,
                                                                 perPage: 25,
                                                                 posProductsOnly: true)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["pos_products_only"] as? String == "true")
    }

    @Test func searchProductsForPointOfSale_includes_posProductsOnly_false_when_default() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.searchProductsForPointOfSale(for: sampleSiteID,
                                                            query: "test",
                                                            productTypes: [.simple],
                                                            pageNumber: 1,
                                                            posProductsOnly: false)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["pos_products_only"] as? String == "false")
    }

    @Test func searchProductsForPointOfSale_includes_posProductsOnly_when_true() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.searchProductsForPointOfSale(for: sampleSiteID,
                                                            query: "test",
                                                            productTypes: [.simple],
                                                            pageNumber: 1,
                                                            posProductsOnly: true)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["pos_products_only"] as? String == "true")
    }

    @Test func loadPOSProductByGlobalUniqueIdentifier_includes_posProductsOnly_false_when_default() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "pos-products")

        // When
        _ = try? await remote.loadPOSProductByGlobalUniqueIdentifier(for: sampleSiteID,
                                                                      globalUniqueID: "123456789",
                                                                      posProductsOnly: false)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.parameters["pos_products_only"] as? String == "false")
    }

    @Test func loadPOSProductByGlobalUniqueIdentifier_includes_posProductsOnly_when_true() async throws {
        // Given
        let remote = ProductsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "pos-products")

        // When
        _ = try? await remote.loadPOSProductByGlobalUniqueIdentifier(for: sampleSiteID,
                                                                      globalUniqueID: "123456789",
                                                                      posProductsOnly: true)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.parameters["pos_products_only"] as? String == "true")
    }

    @Test func loadPOSProduct_includes_posProductsOnly_false_when_default() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.loadPOSProduct(for: sampleSiteID,
                                              productID: 123,
                                              posProductsOnly: false)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.parameters["pos_products_only"] as? String == "false")
    }

    @Test func loadPOSProduct_includes_posProductsOnly_when_true() async throws {
        // Given
        let remote = ProductsRemote(network: network)

        // When
        _ = try? await remote.loadPOSProduct(for: sampleSiteID,
                                              productID: 123,
                                              posProductsOnly: true)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.parameters["pos_products_only"] as? String == "true")
    }
}
