import Foundation
import Testing
@testable import Networking
@testable import NetworkingCore

struct POSCatalogSyncRemoteTests {
    private let network = MockNetwork()
    private let mockBackgroundDownloader = MockBackgroundDownloader()
    private let mockFileManager = MockFileManager()
    private let sampleSiteID: Int64 = 1234
    private let testDefaults: UserDefaults

    init() {
        // Create isolated UserDefaults suite for this test
        testDefaults = UserDefaults(suiteName: "POSCatalogSyncRemoteTests.\(UUID().uuidString)")!
        BackgroundDownloadState.configure(userDefaults: testDefaults)
    }

    @Test func loadProducts_sets_correct_parameters() async throws {
        // Given
        let remote = createRemote()
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
        let remote = createRemote()
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
        let remote = createRemote()

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.loadProducts(modifiedAfter: Date(), siteID: sampleSiteID, pageNumber: 1)
        }
    }

    @Test(arguments: 1...4) func loadProducts_returns_hasMorePages_based_on_header(pageNumber: Int) async throws {
        // Given a response with 5 pages
        let remote = createRemote()
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
        let remote = createRemote()
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
        let remote = createRemote()
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
        let remote = createRemote()
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

    @Test func loadProducts_with_includeStatus_adds_parameter() async throws {
        // Given
        let remote = createRemote()
        let modifiedAfter = Date(timeIntervalSince1970: 1692968400)
        let pageNumber = 1

        // When
        _ = try? await remote.loadProducts(modifiedAfter: modifiedAfter, siteID: sampleSiteID, pageNumber: pageNumber, includeStatus: "trash")

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["include_status"] as? String == "trash")
    }

    @Test func loadProducts_without_includeStatus_omits_parameter() async throws {
        // Given
        let remote = createRemote()
        let modifiedAfter = Date(timeIntervalSince1970: 1692968400)
        let pageNumber = 1

        // When
        _ = try? await remote.loadProducts(modifiedAfter: modifiedAfter, siteID: sampleSiteID, pageNumber: pageNumber, includeStatus: nil)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["include_status"] == nil)
    }

    @Test func loadProducts_includes_status_in_request_fields() async throws {
        // Given
        let remote = createRemote()
        let modifiedAfter = Date()

        // When
        _ = try? await remote.loadProducts(modifiedAfter: modifiedAfter, siteID: sampleSiteID, pageNumber: 1)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        let fieldsString = try #require(queryParametersDictionary["_fields"] as? String)
        #expect(fieldsString.contains("status"))
    }

    // MARK: - Product Variations Tests

    @Test func loadProductVariations_sets_correct_parameters() async throws {
        // Given
        let remote = createRemote()
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
        let remote = createRemote()
        let modifiedAfter = Date()

        // When
        network.simulateResponse(requestUrlSuffix: "variations", filename: "product-variations-load-pos")
        let pagedVariations = try await remote.loadProductVariations(modifiedAfter: modifiedAfter, siteID: sampleSiteID, pageNumber: 1)

        // Then
        #expect(!pagedVariations.items.isEmpty)

        let firstVariation = try #require(pagedVariations.items.first)
        #expect(firstVariation.siteID == sampleSiteID)
        #expect(firstVariation.productVariationID == 123)
        #expect(firstVariation.productID == 119)
    }

    @Test func loadProductVariations_relays_networking_error() async throws {
        // Given
        let remote = createRemote()

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.loadProductVariations(modifiedAfter: Date(), siteID: sampleSiteID, pageNumber: 1)
        }
    }

    @Test func loadProductVariations_returns_hasMorePages_based_on_header() async throws {
        // Given a response with 3 pages
        let remote = createRemote()
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
        let remote = createRemote()
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
        let remote = createRemote()
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
        let remote = createRemote()
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
        let remote = createRemote()
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
        let remote = createRemote()
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
        let remote = createRemote()

        // When
        _ = try? await remote.requestCatalogGeneration(for: sampleSiteID, forceGeneration: false, allowCellular: true)

        // Then
        let queryParametersDictionary = try #require(network.queryParametersDictionary as? [String: any Hashable])
        #expect(queryParametersDictionary["_product_fields"] as? String == POSProduct.requestFields.joined(separator: ","))
        #expect(queryParametersDictionary["_variation_fields"] as? String == POSProductVariation.requestFields.joined(separator: ","))
        #expect(queryParametersDictionary["force"] == nil)
    }

    @Test func generateCatalog_returns_parsed_response() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)

        // When
        network.simulateResponse(requestUrlSuffix: "create", filename: "pos-catalog-generation")
        let response = try await remote.requestCatalogGeneration(for: sampleSiteID, forceGeneration: false, allowCellular: true)

        // Then
        #expect(response.status == .completed)
        #expect(response.downloadURL == "https://example.com/wp-content/uploads/catalog.json")
    }

    @Test func generateCatalog_relays_networking_error() async throws {
        // Given
        let remote = createRemote()

        // When/Then
        await #expect(throws: NetworkError.notFound()) {
            try await remote.requestCatalogGeneration(for: sampleSiteID, forceGeneration: false, allowCellular: true)
        }
    }

    // MARK: - `downloadCatalog` Tests

    @Test func downloadCatalog_returns_parsed_catalog_with_products_and_variations() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        // Loads mock data from existing response file.
        let mockContent = loadMockData(filename: "pos-catalog-download-mixed")
        let mockFileURL = mockBackgroundDownloader.createMockDownloadFile(withContent: mockContent)
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: mockFileURL)

        // When
        let catalog = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)

        // Then
        #expect(catalog.products.count == 2)
        #expect(catalog.variations.count == 3)

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
        #expect(variableProduct.globalUniqueID?.isEmpty == true)
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

        let firstVariation = try #require(catalog.variations.first)
        #expect(firstVariation.siteID == sampleSiteID)
        #expect(firstVariation.productVariationID == 32)
        #expect(firstVariation.productID == 31)
        #expect(firstVariation.sku?.isEmpty == true)
        #expect(firstVariation.globalUniqueID?.isEmpty == true)
        #expect(firstVariation.price == "330.34")
        #expect(firstVariation.attributes.count == 3)
        #expect(firstVariation.image?.src == "https://example.com/wp-content/uploads/2025/08/img-quae.png")
        #expect(firstVariation.attributes == [
            .init(id: 1, name: "Size", option: "Earum"),
            .init(id: 0, name: "ab", option: "deserunt"),
            .init(id: 2, name: "Numeric Size", option: "19")
        ])
        #expect(firstVariation.typeKey == "variation")
    }

    @Test func downloadCatalog_decodes_subscription_variation_as_variation() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        let mockContent = loadMockData(filename: "pos-catalog-download-mixed")
        let mockFileURL = mockBackgroundDownloader.createMockDownloadFile(withContent: mockContent)
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: mockFileURL)

        // When
        let catalog = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)

        // Then: subscription_variation (id: 99) is decoded as a variation with its original typeKey
        #expect(catalog.products.count == 2)
        #expect(catalog.variations.count == 3)
        #expect(catalog.products.contains { $0.productID == 99 } == false)

        let subscriptionVariation = try #require(catalog.variations.first { $0.productVariationID == 99 })
        #expect(subscriptionVariation.typeKey == "subscription_variation")
        #expect(subscriptionVariation.productID == 50)
        #expect(subscriptionVariation.price == "10")
    }

    @Test func downloadCatalog_when_item_has_malformed_data_then_skips_item_without_failing() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        let mockContent = loadMockData(filename: "pos-catalog-download-malformed")
        let mockFileURL = mockBackgroundDownloader.createMockDownloadFile(withContent: mockContent)
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: mockFileURL)

        // When
        let catalog = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)

        // Then: malformed items are skipped, valid item is parsed
        #expect(catalog.products.count == 1)
        #expect(catalog.products.first?.productID == 1)
        #expect(catalog.variations.isEmpty)
    }

    @Test func downloadCatalog_handles_empty_catalog() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        // Set up mock background downloader to return empty array
        let mockFileURL = mockBackgroundDownloader.createMockDownloadFile(withContent: "[]")
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: mockFileURL)

        // When
        let catalog = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)

        // Then
        #expect(catalog.products.isEmpty)
        #expect(catalog.variations.isEmpty)
    }

    @Test func downloadCatalog_throws_error_for_empty_url() async throws {
        // Given
        let remote = createRemote()
        let emptyURL = ""

        // When/Then
        await #expect(throws: NetworkError.invalidURL) {
            try await remote.downloadCatalog(for: sampleSiteID, downloadURL: emptyURL, allowCellular: true)
        }
    }

    @Test func downloadCatalog_relays_download_error() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        let expectedError = BackgroundDownloadError.downloadFailed(NetworkError.notFound())
        mockBackgroundDownloader.mockFailedDownload(error: expectedError)

        // When/Then
        do {
            _ = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is BackgroundDownloadError)
            if case let BackgroundDownloadError.downloadFailed(innerError) = error {
                #expect(innerError is NetworkError)
            } else {
                Issue.record("Expected BackgroundDownloadError.downloadFailed")
            }
        }
    }

    // MARK: - Background Download Tests

    @Test func downloadCatalog_uses_background_downloader_with_correct_parameters() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        // Set up successful mock download
        let mockFileURL = mockBackgroundDownloader.createMockDownloadFile(withContent: "[]")
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: mockFileURL)

        // When
        _ = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)

        // Then
        #expect(mockBackgroundDownloader.downloadCallCount == 1)
        #expect(mockBackgroundDownloader.lastDownloadURL?.absoluteString == downloadURL)
        #expect(mockBackgroundDownloader.lastSessionIdentifier?.contains("com.woocommerce.pos.catalog.download.\(sampleSiteID)") == true)
    }

    @Test func downloadCatalog_generates_unique_session_identifiers() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        // When - make two downloads with separate mock files
        let mockFileURL1 = mockBackgroundDownloader.createMockDownloadFile(withContent: "[]")
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: mockFileURL1)
        _ = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)
        let firstSessionId = mockBackgroundDownloader.lastSessionIdentifier

        let mockFileURL2 = mockBackgroundDownloader.createMockDownloadFile(withContent: "[]")
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: mockFileURL2)
        _ = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)
        let secondSessionId = mockBackgroundDownloader.lastSessionIdentifier

        // Then
        #expect(mockBackgroundDownloader.downloadCallCount == 2)
        #expect(firstSessionId != secondSessionId)
        #expect(firstSessionId?.contains("com.woocommerce.pos.catalog.download.\(sampleSiteID)") == true)
        #expect(secondSessionId?.contains("com.woocommerce.pos.catalog.download.\(sampleSiteID)") == true)
    }

    @Test func downloadCatalog_handles_background_download_cancellation() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        // Set up mock to return cancellation error
        mockBackgroundDownloader.mockFailedDownload(error: BackgroundDownloadError.cancelled)

        // When/Then
        do {
            _ = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is BackgroundDownloadError)
            if case BackgroundDownloadError.cancelled = error {
                // Success - this is the expected error
            } else {
                Issue.record("Expected BackgroundDownloadError.cancelled")
            }
        }

        #expect(mockBackgroundDownloader.downloadCallCount == 1)
    }

    @Test func downloadCatalog_cleans_up_downloaded_file_after_parsing() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        // Create an actual temporary file for testing file cleanup
        let mockContent = loadMockData(filename: "pos-catalog-download-mixed")
        let tempFile = mockBackgroundDownloader.createMockDownloadFile(withContent: mockContent)

        // Move to Documents-like path by creating a file in a Documents subdirectory
        let documentsURL = FileManager.default.temporaryDirectory.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)

        let fileName = "mock_catalog_\(UUID().uuidString).json"
        let documentsFileURL = documentsURL.appendingPathComponent(fileName)
        try FileManager.default.copyItem(at: tempFile, to: documentsFileURL)

        // Configure mock file manager to return this Documents directory
        mockFileManager.mockDocumentsURL = documentsURL
        mockFileManager.mockFileExists = true

        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: documentsFileURL)

        // When
        _ = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)

        // Then - verify file cleanup was called
        #expect(mockFileManager.removeItemCallCount == 1)
        #expect(mockFileManager.lastRemovedURL == documentsFileURL)

        // Cleanup test files
        try? FileManager.default.removeItem(at: documentsURL)
        try? FileManager.default.removeItem(at: tempFile)
    }

    @Test func downloadCatalog_preserves_temporary_files_for_ios_cleanup() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        // Create an actual temporary file (not in Documents directory)
        let mockContent = loadMockData(filename: "pos-catalog-download-mixed")
        let tempFileURL = mockBackgroundDownloader.createMockDownloadFile(withContent: mockContent)
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: tempFileURL)

        // Configure mock file manager - Documents directory is different path
        mockFileManager.mockDocumentsURL = URL(fileURLWithPath: "/some/other/Documents")
        mockFileManager.mockFileExists = true

        // When
        _ = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)

        // Then - temporary files should NOT be cleaned up (no removal call)
        #expect(mockFileManager.removeItemCallCount == 0)

        // Manual cleanup for test hygiene
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    @Test(arguments: [true, false])
    func downloadCatalog_respects_allowCellular_parameter(allowCellular: Bool) async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"
        let mockFileURL = mockBackgroundDownloader.createMockDownloadFile(withContent: "[]")
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: mockFileURL)

        // When
        _ = try await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: allowCellular)

        // Then
        #expect(mockBackgroundDownloader.lastAllowCellular == allowCellular)
    }

    // MARK: - Full Sync allowCellular Tests

    @Test(arguments: [true, false])
    func requestCatalogGeneration_sets_allowsCellularAccess_on_request(allowCellular: Bool) async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "create", filename: "pos-catalog-generation")

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

import NetworkingTestsResponsesFixtures

private extension POSCatalogSyncRemoteTests {
    func createRemote() -> POSCatalogSyncRemote {
        POSCatalogSyncRemote(network: network, backgroundDownloader: mockBackgroundDownloader, fileManager: mockFileManager)
    }

    /// Loads test data from bundle response file.
    func loadMockData(filename: String) -> String {
        let fixturesBundle = NetworkingTestsResponsesFixtures.bundle
        guard let url = fixturesBundle.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let string = String(data: data, encoding: .utf8) else {
            fatalError("Could not load test data from \(filename).json")
        }
        return string
    }
}

// MARK: - MockFileManager

/// Mock FileManager for testing file operations in POSCatalogSyncRemote.
private class MockFileManager: FileManager {
    var mockDocumentsURL: URL?
    var mockFileExists: Bool = false
    var removeItemCallCount: Int = 0
    var lastRemovedURL: URL?

    override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        if directory == .documentDirectory, let mockURL = mockDocumentsURL {
            return [mockURL]
        }
        return []
    }

    override func fileExists(atPath path: String) -> Bool {
        return mockFileExists
    }

    override func removeItem(at URL: URL) throws {
        removeItemCallCount += 1
        lastRemovedURL = URL
    }
}

// MARK: - Background Download State Tests

extension POSCatalogSyncRemoteTests {
    @Test func downloadCatalog_saves_background_state() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        let mockFileURL = mockBackgroundDownloader.createMockDownloadFile(withContent: "[]")
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: mockFileURL)
        network.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-download")

        // When - use continuation to capture state when download starts
        let savedState: BackgroundDownloadState? = await withCheckedContinuation { continuation in
            mockBackgroundDownloader.onDownloadStarted = {
                // Download has started, state should be saved now
                if let sessionIdentifier = mockBackgroundDownloader.lastSessionIdentifier {
                    let state = BackgroundDownloadState.load(for: sessionIdentifier)
                    continuation.resume(returning: state)
                } else {
                    continuation.resume(returning: nil)
                }
            }

            Task {
                _ = try? await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)
            }
        }

        // Then - state should have been saved during download
        #expect(savedState != nil)
        #expect(savedState?.siteID == sampleSiteID)
        #expect(savedState?.sessionIdentifier == mockBackgroundDownloader.lastSessionIdentifier)

        // Cleanup
        try? FileManager.default.removeItem(at: mockFileURL)
    }

    @Test func downloadCatalog_clears_state_on_success() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"

        // When
        let mockFileURL = mockBackgroundDownloader.createMockDownloadFile(withContent: "[]")
        mockBackgroundDownloader.mockSuccessfulDownload(fileURL: mockFileURL)
        network.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-download")
        _ = try? await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)

        // Then - state should be cleared after successful completion
        let savedState = BackgroundDownloadState.load(for: mockBackgroundDownloader.lastSessionIdentifier ?? "")
        #expect(savedState == nil)

        // Cleanup
        try? FileManager.default.removeItem(at: mockFileURL)
    }

    @Test func downloadCatalog_creates_unique_session_identifiers() async throws {
        // Given
        let remote = createRemote()
        let downloadURL = "https://example.com/catalog.json"
        mockBackgroundDownloader.mockFileURL = URL(fileURLWithPath: "/tmp/catalog.json")
        network.simulateResponse(requestUrlSuffix: "catalog", filename: "pos-catalog-download")

        // When - download twice
        _ = try? await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)
        let firstSessionID = mockBackgroundDownloader.lastSessionIdentifier

        _ = try? await remote.downloadCatalog(for: sampleSiteID, downloadURL: downloadURL, allowCellular: true)
        let secondSessionID = mockBackgroundDownloader.lastSessionIdentifier

        // Then - session IDs should be different
        #expect(firstSessionID != secondSessionID)
        #expect(firstSessionID?.hasPrefix("com.woocommerce.pos.catalog.download") == true)
        #expect(secondSessionID?.hasPrefix("com.woocommerce.pos.catalog.download") == true)

        // Cleanup
        BackgroundDownloadState.clear()
    }
}
