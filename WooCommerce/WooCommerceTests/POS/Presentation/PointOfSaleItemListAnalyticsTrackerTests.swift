import Testing
import Foundation
@testable import WooCommerce

struct PointOfSaleItemListAnalyticsTrackerTests {
    @available(iOS 17.0, *)
    @Test func init_products_list_sets_correct_source_and_type() async throws {
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: false), searchTerm: "")
        #expect(tracker.source == .product)
        #expect(tracker.sourceType == .list)
    }

    @available(iOS 17.0, *)
    @Test func init_coupons_list_sets_correct_source_and_type() async throws {
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: false), searchTerm: "")
        #expect(tracker.source == .coupon)
        #expect(tracker.sourceType == .list)
    }

    @available(iOS 17.0, *)
    @Test func init_products_search_emptyTerm_sets_preSearch() async throws {
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: true), searchTerm: "")
        #expect(tracker.source == .product)
        #expect(tracker.sourceType == .preSearch)
    }

    @available(iOS 17.0, *)
    @Test func init_products_search_nonEmptyTerm_sets_search() async throws {
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: true), searchTerm: "shoes")
        #expect(tracker.source == .product)
        #expect(tracker.sourceType == .search)
    }

    @available(iOS 17.0, *)
    @Test func init_coupons_search_emptyTerm_sets_preSearch() async throws {
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: true), searchTerm: "")
        #expect(tracker.source == .coupon)
        #expect(tracker.sourceType == .preSearch)
    }

    @available(iOS 17.0, *)
    @Test func init_coupons_search_nonEmptyTerm_sets_search() async throws {
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: true), searchTerm: "discount")
        #expect(tracker.source == .coupon)
        #expect(tracker.sourceType == .search)
    }
}
