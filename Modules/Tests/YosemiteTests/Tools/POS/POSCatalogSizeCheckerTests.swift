import Foundation
import Testing
@testable import Yosemite

struct POSCatalogSizeCheckerTests {
    private let mockSyncRemote: MockPOSCatalogSyncRemote
    private let sut: POSCatalogSizeChecker
    private let sampleSiteID: Int64 = 134

    init() throws {
        self.mockSyncRemote = MockPOSCatalogSyncRemote()
        self.sut = POSCatalogSizeChecker(syncRemote: mockSyncRemote)
    }

    @Test func checkCatalogSize_returns_combined_count_from_remote() async throws {
        // Given
        mockSyncRemote.getProductCountResult = .success(400)
        mockSyncRemote.getProductVariationCountResult = .success(300)

        // When
        let catalogSize = try await sut.checkCatalogSize(for: sampleSiteID)

        // Then
        #expect(catalogSize.productCount == 400)
        #expect(catalogSize.variationCount == 300)
        #expect(catalogSize.totalCount == 700)
        #expect(mockSyncRemote.getProductCountCallCount == 1)
        #expect(mockSyncRemote.getProductVariationCountCallCount == 1)
        #expect(mockSyncRemote.lastProductCountSiteID == sampleSiteID)
        #expect(mockSyncRemote.lastVariationCountSiteID == sampleSiteID)
    }

    @Test func checkCatalogSize_handles_zero_counts() async throws {
        // Given
        mockSyncRemote.getProductCountResult = .success(0)
        mockSyncRemote.getProductVariationCountResult = .success(0)

        // When
        let catalogSize = try await sut.checkCatalogSize(for: sampleSiteID)

        // Then
        #expect(catalogSize.productCount == 0)
        #expect(catalogSize.variationCount == 0)
        #expect(catalogSize.totalCount == 0)
    }

    @Test func checkCatalogSize_handles_product_count_only() async throws {
        // Given
        mockSyncRemote.getProductCountResult = .success(500)
        mockSyncRemote.getProductVariationCountResult = .success(0)

        // When
        let catalogSize = try await sut.checkCatalogSize(for: sampleSiteID)

        // Then
        #expect(catalogSize.productCount == 500)
        #expect(catalogSize.variationCount == 0)
        #expect(catalogSize.totalCount == 500)
    }

    @Test func checkCatalogSize_handles_variation_count_only() async throws {
        // Given
        mockSyncRemote.getProductCountResult = .success(0)
        mockSyncRemote.getProductVariationCountResult = .success(750)

        // When
        let catalogSize = try await sut.checkCatalogSize(for: sampleSiteID)

        // Then
        #expect(catalogSize.productCount == 0)
        #expect(catalogSize.variationCount == 750)
        #expect(catalogSize.totalCount == 750)
    }

    @Test func checkCatalogSize_propagates_product_count_error() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Products not found"])
        mockSyncRemote.getProductCountResult = .failure(expectedError)
        mockSyncRemote.getProductVariationCountResult = .success(100)

        // When/Then
        await #expect(throws: expectedError) {
            _ = try await sut.checkCatalogSize(for: sampleSiteID)
        }
    }

    @Test func checkCatalogSize_propagates_variation_count_error() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        mockSyncRemote.getProductCountResult = .success(200)
        mockSyncRemote.getProductVariationCountResult = .failure(expectedError)

        // When/Then
        await #expect(throws: expectedError) {
            _ = try await sut.checkCatalogSize(for: sampleSiteID)
        }
    }
}
