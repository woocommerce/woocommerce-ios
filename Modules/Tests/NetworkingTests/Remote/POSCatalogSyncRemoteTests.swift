import Foundation
import Testing
@testable import Networking
@testable import NetworkingCore

struct POSCatalogSyncRemoteTests {
    private let network = MockNetwork()
    private let sampleSiteID: Int64 = 1234

    @Test func loadProducts_sets_correct_parameters() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date(timeIntervalSince1970: 1692968400) // 2023-08-25 12:00:00 UTC
        let pageNumber = 2

        // When
        _ = try? await remote.loadProducts(modifiedAfter: modifiedAfter, siteID: sampleSiteID, pageNumber: pageNumber)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        let dateFormatter = ISO8601DateFormatter()
        let expectedDateString = dateFormatter.string(from: modifiedAfter)

        #expect(queryParametersDictionary["modified_after"] as? String == expectedDateString)
        #expect(queryParametersDictionary["page"] as? String == String(pageNumber))
        #expect(queryParametersDictionary["per_page"] as? String == "100")
        #expect(queryParametersDictionary["_fields"] as? String == POSProduct.requestFields.joined(separator: ","))
    }

    @Test func loadProducts_returns_parsed_products() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date()
        let expectedProductsCount = 2

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-pos")
        let pagedProducts = try await remote.loadProducts(modifiedAfter: modifiedAfter, siteID: sampleSiteID, pageNumber: 1)

        // Then
        #expect(pagedProducts.items.count == expectedProductsCount)

        let firstProduct = try #require(pagedProducts.items.first)
        #expect(firstProduct.siteID == sampleSiteID)
        #expect(firstProduct.productID == 168)
        #expect(firstProduct.name == "Beanie")
        #expect(firstProduct.fullDescription != nil)
        #expect(firstProduct.shortDescription != nil)
    }

    @Test func loadProducts_relays_networking_error() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.loadProducts(modifiedAfter: Date(), siteID: sampleSiteID, pageNumber: 1)
        }
    }

    @Test(arguments: 1...4) func loadProducts_returns_hasMorePages_based_on_header(pageNumber: Int) async throws {
        // Given a response with 5 pages
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date()
        network.responseHeaders = ["X-WP-TotalPages": "5"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When loading page 1 to 4
        let pagedProducts = try await remote.loadProducts(
            modifiedAfter: modifiedAfter,
            siteID: sampleSiteID,
            pageNumber: pageNumber
        )

        // Then there are more pages
        #expect(pagedProducts.hasMorePages == true)
    }

    @Test(arguments: [5, 6]) func loadProducts_returns_false_for_hasMorePages_when_on_last_page(pageNumber: Int) async throws {
        // Given a response with 5 pages
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date()
        network.responseHeaders = ["X-WP-TotalPages": "5"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When loading page 5 or above
        let pagedProducts = try await remote.loadProducts(
            modifiedAfter: modifiedAfter,
            siteID: sampleSiteID,
            pageNumber: pageNumber
        )

        // Then there are no more pages
        #expect(pagedProducts.hasMorePages == false)
    }

    @Test func loadProducts_returns_total_items_from_header() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date()
        let expectedTotalItems = 42
        network.responseHeaders = ["X-WP-Total": "\(expectedTotalItems)"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When
        let pagedProducts = try await remote.loadProducts(
            modifiedAfter: modifiedAfter,
            siteID: sampleSiteID,
            pageNumber: 1
        )

        // Then
        #expect(pagedProducts.totalItems == expectedTotalItems)
    }

    @Test func loadProducts_returns_nil_total_items_when_header_missing() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date()
        network.responseHeaders = nil
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When
        let pagedProducts = try await remote.loadProducts(
            modifiedAfter: modifiedAfter,
            siteID: sampleSiteID,
            pageNumber: 1
        )

        // Then
        #expect(pagedProducts.totalItems == nil)
    }

    // MARK: - Product Variations Tests

    @Test func loadProductVariations_sets_correct_parameters() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date(timeIntervalSince1970: 1692968400) // 2023-08-25 12:00:00 UTC
        let pageNumber = 3

        // When
        _ = try? await remote.loadProductVariations(modifiedAfter: modifiedAfter, siteID: sampleSiteID, pageNumber: pageNumber)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        let dateFormatter = ISO8601DateFormatter()
        let expectedDateString = dateFormatter.string(from: modifiedAfter)

        #expect(queryParametersDictionary["modified_after"] as? String == expectedDateString)
        #expect(queryParametersDictionary["page"] as? String == String(pageNumber))
        #expect(queryParametersDictionary["per_page"] as? String == "100")
        #expect(queryParametersDictionary["_fields"] as? String == POSProductVariation.requestFields.joined(separator: ","))
    }

    @Test func loadProductVariations_returns_parsed_variations() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date()

        // When
        network.simulateResponse(requestUrlSuffix: "variations", filename: "product-variations-load-pos")
        let pagedVariations = try await remote.loadProductVariations(modifiedAfter: modifiedAfter, siteID: sampleSiteID, pageNumber: 1)

        // Then
        #expect(pagedVariations.items.count > 0)

        let firstVariation = try #require(pagedVariations.items.first)
        #expect(firstVariation.siteID == sampleSiteID)
        #expect(firstVariation.productVariationID == 123)
        #expect(firstVariation.productID == 119)
    }

    @Test func loadProductVariations_relays_networking_error() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.loadProductVariations(modifiedAfter: Date(), siteID: sampleSiteID, pageNumber: 1)
        }
    }

    @Test func loadProductVariations_returns_hasMorePages_based_on_header() async throws {
        // Given a response with 3 pages
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date()
        network.responseHeaders = ["X-WP-TotalPages": "3"]
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When loading page 1
        let pagedVariations = try await remote.loadProductVariations(
            modifiedAfter: modifiedAfter,
            siteID: sampleSiteID,
            pageNumber: 1
        )

        // Then there are more pages
        #expect(pagedVariations.hasMorePages == true)
    }

    @Test func loadProductVariations_returns_false_for_hasMorePages_when_on_last_page() async throws {
        // Given a response with 3 pages
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date()
        network.responseHeaders = ["X-WP-TotalPages": "3"]
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When loading page 3
        let pagedVariations = try await remote.loadProductVariations(
            modifiedAfter: modifiedAfter,
            siteID: sampleSiteID,
            pageNumber: 3
        )

        // Then there are no more pages
        #expect(pagedVariations.hasMorePages == false)
    }

    @Test func loadProductVariations_returns_total_items_from_header() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date()
        let expectedTotalItems = 15
        network.responseHeaders = ["X-WP-Total": "\(expectedTotalItems)"]
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When
        let pagedVariations = try await remote.loadProductVariations(
            modifiedAfter: modifiedAfter,
            siteID: sampleSiteID,
            pageNumber: 1
        )

        // Then
        #expect(pagedVariations.totalItems == expectedTotalItems)
    }

    // MARK: - Edge Cases

    @Test func handles_very_old_date() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let veryOldDate = Date(timeIntervalSince1970: 0) // January 1, 1970

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")
        _ = try? await remote.loadProducts(modifiedAfter: veryOldDate, siteID: sampleSiteID, pageNumber: 1)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        let dateString = try #require(queryParametersDictionary["modified_after"] as? String)
        #expect(dateString == "1970-01-01T00:00:00Z")
    }

    @Test func handles_future_date() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let futureDate = Date(timeIntervalSince1970: 4102444800) // January 1, 2100

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")
        _ = try? await remote.loadProducts(modifiedAfter: futureDate, siteID: sampleSiteID, pageNumber: 1)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        let dateString = try #require(queryParametersDictionary["modified_after"] as? String)
        #expect(dateString == "2100-01-01T00:00:00Z")
    }

    @Test func handles_large_page_number() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let modifiedAfter = Date()
        let largePageNumber = 999999

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")
        _ = try? await remote.loadProducts(modifiedAfter: modifiedAfter, siteID: sampleSiteID, pageNumber: largePageNumber)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["page"] as? String == String(largePageNumber))
    }

    @Test func loadProducts_fullSync_returns_hasMorePages_based_on_header() async throws {
        // Given a response with 3 pages
        let remote = POSCatalogSyncRemote(network: network)
        network.responseHeaders = ["X-WP-TotalPages": "3"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When loading page 1
        let pagedProducts = try await remote.loadProducts(siteID: sampleSiteID, pageNumber: 1, allowCellular: true)

        // Then there are more pages
        #expect(pagedProducts.hasMorePages == true)
    }

    // MARK: - Full Sync Product Tests

    @Test func loadProducts_fullSync_sets_correct_parameters() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let pageNumber = 2

        // When
        _ = try? await remote.loadProducts(siteID: sampleSiteID, pageNumber: pageNumber, allowCellular: true)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["page"] as? String == String(pageNumber))
        #expect(queryParametersDictionary["per_page"] as? String == "100")
        #expect(queryParametersDictionary["_fields"] as? String == POSProduct.requestFields.joined(separator: ","))
        #expect(queryParametersDictionary["modified_after"] == nil)
    }

    @Test func loadProducts_fullSync_returns_parsed_products() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let expectedProductsCount = 2

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-pos")
        let pagedProducts = try await remote.loadProducts(siteID: sampleSiteID, pageNumber: 1, allowCellular: true)

        // Then
        #expect(pagedProducts.items.count == expectedProductsCount)

        let firstProduct = try #require(pagedProducts.items.first)
        #expect(firstProduct.siteID == sampleSiteID)
        #expect(firstProduct.productID == 168)
        #expect(firstProduct.name == "Beanie")
    }

    @Test func loadProducts_fullSync_relays_networking_error() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.loadProducts(siteID: sampleSiteID, pageNumber: 1, allowCellular: true)
        }
    }

    // MARK: - Full Sync Product Variations Tests

    @Test func loadProductVariations_fullSync_sets_correct_parameters() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let pageNumber = 3

        // When
        _ = try? await remote.loadProductVariations(siteID: sampleSiteID, pageNumber: pageNumber, allowCellular: true)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["page"] as? String == String(pageNumber))
        #expect(queryParametersDictionary["per_page"] as? String == "100")
        #expect(queryParametersDictionary["_fields"] as? String == POSProductVariation.requestFields.joined(separator: ","))
        #expect(queryParametersDictionary["modified_after"] == nil)
    }

    @Test func loadProductVariations_fullSync_returns_parsed_variations() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When
        network.simulateResponse(requestUrlSuffix: "variations", filename: "product-variations-load-pos")
        let pagedVariations = try await remote.loadProductVariations(siteID: sampleSiteID, pageNumber: 1, allowCellular: true)

        // Then
        #expect(pagedVariations.items.count == 1)

        let firstVariation = try #require(pagedVariations.items.first)
        #expect(firstVariation.siteID == sampleSiteID)
        #expect(firstVariation.productVariationID == 123)
        #expect(firstVariation.productID == 119)
    }

    @Test func loadProductVariations_fullSync_relays_networking_error() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.loadProductVariations(siteID: sampleSiteID, pageNumber: 1, allowCellular: true)
        }
    }

    @Test func loadProductVariations_fullSync_returns_hasMorePages_based_on_header() async throws {
        // Given a response with 3 pages
        let remote = POSCatalogSyncRemote(network: network)
        network.responseHeaders = ["X-WP-TotalPages": "3"]
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When loading page 1
        let pagedVariations = try await remote.loadProductVariations(siteID: sampleSiteID, pageNumber: 1, allowCellular: true)

        // Then there are more pages
        #expect(pagedVariations.hasMorePages == true)
    }

    @Test func posProductVariation_provides_field_names_for_request() {
        let fieldNames = POSProductVariation.requestFields
        #expect(fieldNames.contains("id"))
        #expect(fieldNames.contains("parent_id"))
        #expect(fieldNames.contains("attributes"))
        #expect(fieldNames.contains("image"))
        #expect(fieldNames.contains("price"))
        #expect(fieldNames.contains("description"))
        #expect(fieldNames.contains("sku"))
        #expect(fieldNames.contains("global_unique_id"))
        #expect(fieldNames.contains("downloadable"))
        #expect(fieldNames.contains("description"))
        #expect(fieldNames.contains("manage_stock"))
        #expect(fieldNames.contains("stock_quantity"))
        #expect(fieldNames.contains("stock_status"))
    }

    // MARK: - Count Endpoints Tests

    @Test func getProductCount_uses_correct_path() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.responseHeaders = ["X-WP-Total": "150"]

        // When
        _ = try? await remote.getProductCount(siteID: sampleSiteID)

        // Then - verify correct path was used
        let request = try #require(network.requestsForResponseData.last as? JetpackRequest)
        #expect(request.path.contains("products"))
    }

    @Test func getProductCount_returns_count_from_total_header() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let expectedCount = 500
        network.responseHeaders = ["X-WP-Total": "\(expectedCount)"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When
        let count = try await remote.getProductCount(siteID: sampleSiteID)

        // Then
        #expect(count == expectedCount)
    }

    @Test func getProductCount_returns_zero_when_header_missing() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.responseHeaders = nil
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When
        let count = try await remote.getProductCount(siteID: sampleSiteID)

        // Then
        #expect(count == 0)
    }

    @Test func getProductCount_returns_zero_when_header_invalid() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.responseHeaders = ["X-WP-Total": "invalid-number"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When
        let count = try await remote.getProductCount(siteID: sampleSiteID)

        // Then
        #expect(count == 0)
    }

    @Test func getProductCount_relays_networking_error() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.getProductCount(siteID: sampleSiteID)
        }
    }

    @Test func getProductVariationCount_uses_correct_path() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.responseHeaders = ["X-WP-Total": "75"]
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When
        _ = try? await remote.getProductVariationCount(siteID: sampleSiteID)

        // Then - verify correct path was used
        let request = try #require(network.requestsForResponseData.last as? JetpackRequest)
        #expect(request.path.contains("variations"))
    }

    @Test func getProductVariationCount_returns_count_from_total_header() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let expectedCount = 250
        network.responseHeaders = ["X-WP-Total": "\(expectedCount)"]
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When
        let count = try await remote.getProductVariationCount(siteID: sampleSiteID)

        // Then
        #expect(count == expectedCount)
    }

    @Test func getProductVariationCount_returns_zero_when_header_missing() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.responseHeaders = nil
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When
        let count = try await remote.getProductVariationCount(siteID: sampleSiteID)

        // Then
        #expect(count == 0)
    }

    @Test func getProductVariationCount_returns_zero_when_header_invalid() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.responseHeaders = ["X-WP-Total": "not-a-number"]
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When
        let count = try await remote.getProductVariationCount(siteID: sampleSiteID)

        // Then
        #expect(count == 0)
    }

    @Test func getProductVariationCount_relays_networking_error() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.getProductVariationCount(siteID: sampleSiteID)
        }
    }

    @Test func getProductCount_handles_very_large_counts() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let largeCount = 999999
        network.responseHeaders = ["X-WP-Total": "\(largeCount)"]
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When
        let count = try await remote.getProductCount(siteID: sampleSiteID)

        // Then
        #expect(count == largeCount)
    }

    @Test func getProductVariationCount_handles_very_large_counts() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let largeCount = 888888
        network.responseHeaders = ["X-WP-Total": "\(largeCount)"]
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When
        let count = try await remote.getProductVariationCount(siteID: sampleSiteID)

        // Then
        #expect(count == largeCount)
    }

    @Test func count_endpoints_use_correct_api_versions() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.responseHeaders = ["X-WP-Total": "10"]

        // When - make both count calls
        _ = try? await remote.getProductCount(siteID: sampleSiteID)
        _ = try? await remote.getProductVariationCount(siteID: sampleSiteID)

        // Then - verify API versions match the data endpoints
        // This is verified by checking that the correct paths are called
        let requests = network.requestsForResponseData.compactMap { $0 as? JetpackRequest }
        #expect(requests.contains { $0.path.contains("products") })
        #expect(requests.contains { $0.path.contains("variations") })
    }

    // MARK: - `requestCatalogGeneration` Tests

    @Test func generateCatalog_sets_correct_parameters() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When
        _ = try? await remote.requestCatalogGeneration(for: sampleSiteID, forceGeneration: false, allowCellular: true)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["fields"] as? [String] == POSProduct.requestFields)
        #expect(queryParametersDictionary["force_generate"] as? Bool == false)
    }

    @Test func generateCatalog_returns_parsed_response() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When
        network.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-generation")
        let response = try await remote.requestCatalogGeneration(for: sampleSiteID, forceGeneration: false, allowCellular: true)

        // Then
        #expect(response.status == .complete)
        #expect(response.downloadURL == "https://example.com/wp-content/uploads/catalog.json")
    }

    @Test func generateCatalog_relays_networking_error() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.requestCatalogGeneration(for: sampleSiteID, forceGeneration: false, allowCellular: true)
        }
    }

    // MARK: - `downloadCatalog` Tests

    @Test func downloadCatalog_returns_parsed_catalog_with_products_and_variations() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let downloadURL = "https://example.com/catalog.json"

        // When
        network.simulateResponse(requestUrlSuffix: "", filename: "pos-catalog-download-mixed")
        let catalog = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)

        // Then
        #expect(catalog.products.count == 2)
        #expect(catalog.variations.count == 2)

        let simpleProduct = try #require(catalog.products.first { $0.productType == .simple })
        #expect(simpleProduct.siteID == sampleSiteID)
        #expect(simpleProduct.productID == 48)
        #expect(simpleProduct.sku == "synergistic-copper-clock-61732018")
        #expect(simpleProduct.globalUniqueID == "61732018")
        #expect(simpleProduct.name == "Synergistic Copper Clock")
        #expect(simpleProduct.price == "220")
        #expect(simpleProduct.stockStatusKey == "instock")
        #expect(simpleProduct.images.count == 1)
        #expect(simpleProduct.images.first?.src == "https://example.com/wp-content/uploads/2025/08/img-ad.png")

        let variableProduct = try #require(catalog.products.first { $0.productType == .variable })
        #expect(variableProduct.siteID == sampleSiteID)
        #expect(variableProduct.productID == 31)
        #expect(variableProduct.sku == "incredible-silk-chair-13060312")
        #expect(variableProduct.globalUniqueID == "")
        #expect(variableProduct.name == "Incredible Silk Chair")
        #expect(variableProduct.price == "134.58")
        #expect(variableProduct.stockQuantity == -83)
        #expect(variableProduct.images.count == 1)
        #expect(variableProduct.images.first?.src == "https://example.com/wp-content/uploads/2025/08/img-harum.png")
        #expect(variableProduct.attributes == [
            .init(siteID: sampleSiteID, attributeID: 1, name: "Size", position: 0, visible: true, variation: true, options: ["Earum"]),
            .init(siteID: sampleSiteID, attributeID: 0, name: "Ab", position: 1, visible: true, variation: true, options: ["deserunt", "ea", "ut"]),
            .init(siteID: sampleSiteID,
                  attributeID: 2,
                  name: "Numeric Size",
                  position: 2,
                  visible: true,
                  variation: true,
                  options: ["19", "8", "9", "At", "Reiciendis"])
        ])

        let variation = try #require(catalog.variations.first)
        #expect(variation.siteID == sampleSiteID)
        #expect(variation.productVariationID == 32)
        #expect(variation.productID == 31)
        #expect(variation.sku == "")
        #expect(variation.globalUniqueID == "")
        #expect(variation.price == "330.34")
        #expect(variation.attributes.count == 3)
        #expect(variation.image?.src == "https://example.com/wp-content/uploads/2025/08/img-quae.png")
        #expect(variation.attributes == [
            .init(id: 1, name: "Size", option: "Earum"),
            .init(id: 0, name: "ab", option: "deserunt"),
            .init(id: 2, name: "Numeric Size", option: "19")
        ])
    }

    @Test func downloadCatalog_handles_empty_catalog() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let downloadURL = "https://example.com/catalog.json"

        // When
        network.simulateResponse(requestUrlSuffix: "", filename: "empty-data-array")
        let catalog = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)

        // Then
        #expect(catalog.products.count == 0)
        #expect(catalog.variations.count == 0)
    }

    @Test func downloadCatalog_throws_error_for_empty_url() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let emptyURL = ""

        // When/Then
        await #expect(throws: NetworkError.invalidURL) {
            try await remote.downloadCatalog(for: sampleSiteID, downloadURL: emptyURL, allowCellular: true)
        }
    }

    @Test func downloadCatalog_relays_networking_error() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let downloadURL = "https://example.com/catalog.json"

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)
        }
    }

    @Test(arguments: [true, false])
    func downloadCatalog_sets_allowsCellularAccess_on_request(allowCellular: Bool) async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let downloadURL = "https://example.com/catalog.json"
        network.simulateResponse(requestUrlSuffix: "", filename: "empty-data-array")

        // When
        _ = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: allowCellular)

        // Then
        let urlRequest = try #require(network.requestsForResponseData.last as? URLRequest)
        #expect(urlRequest.allowsCellularAccess == allowCellular)
    }

    // MARK: - Full Sync allowCellular Tests

    @Test(arguments: [true, false])
    func requestCatalogGeneration_sets_allowsCellularAccess_on_request(allowCellular: Bool) async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-generation")

        // When
        _ = try await remote.requestCatalogGeneration(for: sampleSiteID, forceGeneration: false, allowCellular: allowCellular)

        // Then
        let jetpackRequest = try #require(network.requestsForResponseData.last as? JetpackRequest)
        let urlRequest = try jetpackRequest.asURLRequest()
        #expect(urlRequest.allowsCellularAccess == allowCellular)
    }

    @Test(arguments: [true, false])
    func loadProducts_fullSync_sets_allowsCellularAccess_on_request(allowCellular: Bool) async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When
        _ = try await remote.loadProducts(siteID: sampleSiteID, pageNumber: 1, allowCellular: allowCellular)

        // Then
        let jetpackRequest = try #require(network.requestsForResponseData.last as? JetpackRequest)
        let urlRequest = try jetpackRequest.asURLRequest()
        #expect(urlRequest.allowsCellularAccess == allowCellular)
    }

    @Test(arguments: [true, false])
    func loadProductVariations_fullSync_sets_allowsCellularAccess_on_request(allowCellular: Bool) async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When
        _ = try await remote.loadProductVariations(siteID: sampleSiteID, pageNumber: 1, allowCellular: allowCellular)

        // Then
        let jetpackRequest = try #require(network.requestsForResponseData.last as? JetpackRequest)
        let urlRequest = try jetpackRequest.asURLRequest()
        #expect(urlRequest.allowsCellularAccess == allowCellular)
    }
}
