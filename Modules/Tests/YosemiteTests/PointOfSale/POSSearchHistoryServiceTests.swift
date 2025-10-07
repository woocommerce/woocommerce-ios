import Testing
import Foundation
@testable import Yosemite

struct POSSearchHistoryServiceTests {
    private var sut: POSSearchHistoryService!
    private var mockStoreMethods: MockSiteSpecificAppSettingsStoreMethods!
    private let siteID: Int64 = 123

    init() {
        mockStoreMethods = MockSiteSpecificAppSettingsStoreMethods()
        mockStoreMethods.currentSiteID = siteID
        sut = POSSearchHistoryService(maxHistorySize: 10, siteID: siteID, siteSpecificAppSettingsStoreMethods: mockStoreMethods)
    }

    @Test func saveSuccessfulSearch_saves_term_to_history() throws {
        // Given
        let itemType: POSItemType = .product

        // When
        sut.saveSuccessfulSearch(term: "test", for: itemType)

        // Then
        let history = try #require(mockStoreMethods.mockSearchTerms[itemType])
        #expect(history.count == 1)
        #expect(history.first == "test")
    }

    @Test func saveSuccessfulSearch_orders_terms_by_recency() throws {
        // Given
        let itemType: POSItemType = .product

        // When
        sut.saveSuccessfulSearch(term: "first", for: itemType)
        sut.saveSuccessfulSearch(term: "second", for: itemType)
        sut.saveSuccessfulSearch(term: "third", for: itemType)

        // Then
        let history = try #require(mockStoreMethods.mockSearchTerms[itemType])
        #expect(history.count == 3)
        #expect(history[0] == "third")
        #expect(history[1] == "second")
        #expect(history[2] == "first")
    }

    @Test func saveSuccessfulSearch_removes_duplicates() throws {
        // Given
        let itemType: POSItemType = .product

        // When
        sut.saveSuccessfulSearch(term: "test", for: itemType)
        sut.saveSuccessfulSearch(term: "another", for: itemType)
        sut.saveSuccessfulSearch(term: "test", for: itemType)

        // Then
        let history = try #require(mockStoreMethods.mockSearchTerms[itemType])
        #expect(history.count == 2)
        #expect(history[0] == "test")
        #expect(history[1] == "another")
    }

    @Test func saveSuccessfulSearch_respects_max_history_size() throws {
        // Given
        let sut = POSSearchHistoryService(maxHistorySize: 3, siteID: siteID, siteSpecificAppSettingsStoreMethods: mockStoreMethods)
        let itemType: POSItemType = .product

        // When
        sut.saveSuccessfulSearch(term: "first", for: itemType)
        sut.saveSuccessfulSearch(term: "second", for: itemType)
        sut.saveSuccessfulSearch(term: "third", for: itemType)
        sut.saveSuccessfulSearch(term: "fourth", for: itemType)

        // Then
        let history = try #require(mockStoreMethods.mockSearchTerms[itemType])
        #expect(history.count == 3)
        #expect(history[0] == "fourth")
        #expect(history[1] == "third")
        #expect(history[2] == "second")
    }

    @Test func searchHistory_returns_empty_array_for_unknown_item_type() {
        // Given
        let itemType: POSItemType = .coupon

        // When
        let history = sut.searchHistory(for: itemType)

        // Then
        #expect(history.isEmpty)
    }

    @Test func search_history_is_separate_for_different_item_types() {
        // Given
        mockStoreMethods.mockSearchTerms[.product] = ["product"]
        mockStoreMethods.mockSearchTerms[.coupon] = ["coupon"]

        // When
        let productsHistory = sut.searchHistory(for: .product)
        let couponsHistory = sut.searchHistory(for: .coupon)

        // Then
        #expect(productsHistory.count == 1)
        #expect(productsHistory.first == "product")
        #expect(couponsHistory.count == 1)
        #expect(couponsHistory.first == "coupon")
    }
}
