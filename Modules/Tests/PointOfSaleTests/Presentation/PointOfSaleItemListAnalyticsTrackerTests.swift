import Testing
import Foundation
import enum WooFoundationCore.WooAnalyticsStat
@testable import PointOfSale

private enum AnalyticsKeys {
    static let type = "type"
    static let source = "source"
    static let sourceType = "source_type"
}

struct PointOfSaleItemListAnalyticsTrackerTests {
    @Test func trackItemListSelected_tracks_correct_event_products_list() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: false), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackItemListSelected(itemListType: .products(search: false))

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsHeaderTapped.rawValue)
        #expect(event.properties[AnalyticsKeys.type] as? String == "product")
    }

    @Test func trackItemListSelected_tracks_correct_event_products_search() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: true), searchTerm: "shoes", analytics: mockAnalytics)

        // When
        tracker.trackItemListSelected(itemListType: .products(search: true))

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsHeaderTapped.rawValue)
        #expect(event.properties[AnalyticsKeys.type] as? String == "product")
    }

    @Test func trackItemListSelected_tracks_correct_event_coupons_list() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: false), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackItemListSelected(itemListType: .coupons(search: false))

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsHeaderTapped.rawValue)
        #expect(event.properties[AnalyticsKeys.type] as? String == "coupon")
    }

    @Test func trackItemListSelected_tracks_correct_event_coupons_search() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: true), searchTerm: "discount", analytics: mockAnalytics)

        // When
        tracker.trackItemListSelected(itemListType: .coupons(search: true))

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsHeaderTapped.rawValue)
        #expect(event.properties[AnalyticsKeys.type] as? String == "coupon")
    }

    @Test func trackNextPageWillLoad_tracks_correct_event_products_list() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: false), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackNextPageWillLoad()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsNextPageLoaded.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "product")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "list")
    }


    @Test func trackNextPageWillLoad_tracks_correct_event_products_preSearch() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: true), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackNextPageWillLoad()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsNextPageLoaded.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "product")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "pre_search")
    }

    @Test func trackNextPageWillLoad_tracks_correct_event_products_search() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: true), searchTerm: "shoes", analytics: mockAnalytics)

        // When
        tracker.trackNextPageWillLoad()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsNextPageLoaded.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "product")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "search")
    }

    @Test func trackNextPageWillLoad_tracks_correct_event_coupons_list() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: false), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackNextPageWillLoad()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsNextPageLoaded.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "coupon")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "list")
    }

    @Test func trackNextPageWillLoad_tracks_correct_event_coupons_preSearch() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: true), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackNextPageWillLoad()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsNextPageLoaded.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "coupon")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "pre_search")
    }

    @Test func trackNextPageWillLoad_tracks_correct_event_coupons_search() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: true), searchTerm: "discount", analytics: mockAnalytics)

        // When
        tracker.trackNextPageWillLoad()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsNextPageLoaded.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "coupon")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "search")
    }

    @Test func trackRefresh_tracks_correct_event_products_list() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: false), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackRefresh()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsPullToRefresh.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "product")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "list")
    }

    @Test func trackRefresh_tracks_correct_event_products_preSearch() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: true), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackRefresh()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsPullToRefresh.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "product")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "pre_search")
    }

    @Test func trackRefresh_tracks_correct_event_products_search() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: true), searchTerm: "shoes", analytics: mockAnalytics)

        // When
        tracker.trackRefresh()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsPullToRefresh.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "product")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "search")
    }

    @Test func trackRefresh_tracks_correct_event_coupons_list() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: false), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackRefresh()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsPullToRefresh.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "coupon")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "list")
    }

    @Test func trackRefresh_tracks_correct_event_coupons_preSearch() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: true), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackRefresh()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsPullToRefresh.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "coupon")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "pre_search")
    }

    @Test func trackRefresh_tracks_correct_event_coupons_search() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: true), searchTerm: "discount", analytics: mockAnalytics)

        // When
        tracker.trackRefresh()

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleItemsPullToRefresh.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "coupon")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "search")
    }

    @Test func trackSearchTapped_tracks_correct_event_products_list() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: false), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackSearchTapped(itemListType: .products(search: false))

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleSearchButtonTapped.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "product")
    }

    @Test func trackSearchTapped_tracks_correct_event_products_search() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .products(search: true), searchTerm: "shoes", analytics: mockAnalytics)

        // When
        tracker.trackSearchTapped(itemListType: .products(search: true))

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleSearchButtonTapped.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "product")
    }

    @Test func trackSearchTapped_tracks_correct_event_coupons_list() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: false), searchTerm: "", analytics: mockAnalytics)

        // When
        tracker.trackSearchTapped(itemListType: .coupons(search: false))

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleSearchButtonTapped.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "coupon")
    }

    @Test func trackSearchTapped_tracks_correct_event_coupons_search() async throws {
        // Given
        let mockAnalytics = MockPOSAnalytics()
        let tracker = PointOfSaleItemListAnalyticsTracker(selectedItemListType: .coupons(search: true), searchTerm: "discount", analytics: mockAnalytics)

        // When
        tracker.trackSearchTapped(itemListType: .coupons(search: true))

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleSearchButtonTapped.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "coupon")
    }
}
