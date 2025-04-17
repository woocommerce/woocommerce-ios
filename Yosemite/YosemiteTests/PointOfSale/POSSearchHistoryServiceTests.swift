import Testing
import Foundation
@testable import Yosemite

struct POSSearchHistoryServiceTests {
    private var sut: POSSearchHistoryService!
    private var mockStoreMethods: MockSiteSpecificAppSettingsStoreMethods!
    private let siteID: Int64 = 123

    init() {
        mockStoreMethods = MockSiteSpecificAppSettingsStoreMethods()
        sut = POSSearchHistoryService(maxHistorySize: 10, siteID: siteID, siteSpecificAppSettingsStoreMethods: mockStoreMethods)
    }

    @Test func saveSuccessfulSearch_saves_term_to_history() {
        // Given
        let itemType: POSItemType = .product

        // When
        sut.saveSuccessfulSearch(term: "test", for: itemType)

        // Then
        let history = sut.searchHistory(for: itemType)
        #expect(history.count == 1)
        #expect(history.first == "test")
    }

    @Test func saveSuccessfulSearch_orders_terms_by_recency() {
        // Given
        let itemType: POSItemType = .product

        // When
        sut.saveSuccessfulSearch(term: "first", for: itemType)
        sut.saveSuccessfulSearch(term: "second", for: itemType)
        sut.saveSuccessfulSearch(term: "third", for: itemType)

        // Then
        let history = sut.searchHistory(for: itemType)
        #expect(history.count == 3)
        #expect(history[0] == "third")
        #expect(history[1] == "second")
        #expect(history[2] == "first")
    }

    @available(iOS 17.0, *)
    @Test func saveSuccessfulSearch_removes_duplicates() {
        // Given
        let itemType: POSItemType = .product

        // When
        sut.saveSuccessfulSearch(term: "test", for: itemType)
        sut.saveSuccessfulSearch(term: "another", for: itemType)
        sut.saveSuccessfulSearch(term: "test", for: itemType)

        // Then
        let history = sut.searchHistory(for: itemType)
        #expect(history.count == 2)
        #expect(history[0] == "test")
        #expect(history[1] == "another")
    }

    @Test func saveSuccessfulSearch_respects_max_history_size() {
        // Given
        let sut = POSSearchHistoryService(maxHistorySize: 3, siteID: siteID, siteSpecificAppSettingsStoreMethods: mockStoreMethods)
        let itemType: POSItemType = .product

        // When
        sut.saveSuccessfulSearch(term: "first", for: itemType)
        sut.saveSuccessfulSearch(term: "second", for: itemType)
        sut.saveSuccessfulSearch(term: "third", for: itemType)
        sut.saveSuccessfulSearch(term: "fourth", for: itemType)

        // Then
        let history = sut.searchHistory(for: itemType)
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

    @Test func clearSearchHistory_clears_history_for_specific_item_type() {
        // Given
        let productsType: POSItemType = .product
        let couponsType: POSItemType = .coupon

        sut.saveSuccessfulSearch(term: "product", for: productsType)
        sut.saveSuccessfulSearch(term: "coupon", for: couponsType)

        // When
        sut.clearSearchHistory(for: productsType)

        // Then
        #expect(sut.searchHistory(for: productsType).isEmpty)
        #expect(sut.searchHistory(for: couponsType).count == 1)
        #expect(sut.searchHistory(for: couponsType).first == "coupon")
    }

    @Test func clearAllSearchHistory_clears_all_history() {
        // Given
        let productsType: POSItemType = .product
        let couponsType: POSItemType = .coupon

        sut.saveSuccessfulSearch(term: "product", for: productsType)
        sut.saveSuccessfulSearch(term: "coupon", for: couponsType)

        // When
        sut.clearAllSearchHistory()

        // Then
        #expect(sut.searchHistory(for: productsType).isEmpty)
        #expect(sut.searchHistory(for: couponsType).isEmpty)
    }

    @Test func search_history_is_separate_for_different_item_types() {
        // Given
        let productsType: POSItemType = .product
        let couponsType: POSItemType = .coupon

        // When
        sut.saveSuccessfulSearch(term: "product", for: productsType)
        sut.saveSuccessfulSearch(term: "coupon", for: couponsType)

        // Then
        let productsHistory = sut.searchHistory(for: productsType)
        let couponsHistory = sut.searchHistory(for: couponsType)

        #expect(productsHistory.count == 1)
        #expect(productsHistory.first == "product")
        #expect(couponsHistory.count == 1)
        #expect(couponsHistory.first == "coupon")
    }
}
