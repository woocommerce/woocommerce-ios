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
        let pagedProducts = try await remote.loadProducts(siteID: sampleSiteID, pageNumber: 1)

        // Then there are more pages
        #expect(pagedProducts.hasMorePages == true)
    }

    // MARK: - Full Sync Product Tests

    @Test func loadProducts_fullSync_sets_correct_parameters() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let pageNumber = 2

        // When
        _ = try? await remote.loadProducts(siteID: sampleSiteID, pageNumber: pageNumber)

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
        let pagedProducts = try await remote.loadProducts(siteID: sampleSiteID, pageNumber: 1)

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
            try await remote.loadProducts(siteID: sampleSiteID, pageNumber: 1)
        }
    }

    // MARK: - Full Sync Product Variations Tests

    @Test func loadProductVariations_fullSync_sets_correct_parameters() async throws {
        // Given
        let remote = POSCatalogSyncRemote(network: network)
        let pageNumber = 3

        // When
        _ = try? await remote.loadProductVariations(siteID: sampleSiteID, pageNumber: pageNumber)

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
        let pagedVariations = try await remote.loadProductVariations(siteID: sampleSiteID, pageNumber: 1)

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
            try await remote.loadProductVariations(siteID: sampleSiteID, pageNumber: 1)
        }
    }

    @Test func loadProductVariations_fullSync_returns_hasMorePages_based_on_header() async throws {
        // Given a response with 3 pages
        let remote = POSCatalogSyncRemote(network: network)
        network.responseHeaders = ["X-WP-TotalPages": "3"]
        network.simulateResponse(requestUrlSuffix: "variations", filename: "empty-data-array")

        // When loading page 1
        let pagedVariations = try await remote.loadProductVariations(siteID: sampleSiteID, pageNumber: 1)

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
}
