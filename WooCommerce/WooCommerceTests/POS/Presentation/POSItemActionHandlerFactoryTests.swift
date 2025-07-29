import Testing
import Foundation
@testable import WooCommerce
import WooFoundation
import enum Yosemite.POSItem

private enum AnalyticsKeys {
    static let source = "source"
    static let sourceType = "source_type"
    static let itemType = "item_type"
    static let productType = "product_type"
}

struct POSItemActionHandlerFactoryTests {
    @available(iOS 17.0, *)
    @Test func products_list_tracks_correct_analytics() async throws {
        // Given
        let posModel = MockPointOfSaleAggregateModel()
        let mockAnalytics = MockPOSAnalytics()
        let handler = POSItemActionHandlerFactory.itemActionHandler(
            itemListType: .products(search: false),
            searchTerm: "",
            posModel: posModel,
            analytics: mockAnalytics
        )
        let item = makeProductItem()

        // When
        handler.handleTap(item)

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleAddItemToCart.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "product")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "list")
        #expect(event.properties[AnalyticsKeys.itemType] as? String == "product")
        #expect(event.properties[AnalyticsKeys.productType] as? String == "simple")
    }

    @available(iOS 17.0, *)
    @Test func coupons_list_tracks_correct_analytics() async throws {
        // Given
        let posModel = MockPointOfSaleAggregateModel()
        let mockAnalytics = MockPOSAnalytics()
        let handler = POSItemActionHandlerFactory.itemActionHandler(
            itemListType: .coupons(search: false),
            searchTerm: "",
            posModel: posModel,
            analytics: mockAnalytics
        )
        let item = makeCouponItem()

        // When
        handler.handleTap(item)

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleAddItemToCart.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "coupon")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "list")
        #expect(event.properties[AnalyticsKeys.itemType] as? String == "coupon")
        #expect(event.properties[AnalyticsKeys.productType] == nil)
    }

    @available(iOS 17.0, *)
    @Test func products_search_tracks_correct_analytics() async throws {
        // Given
        let posModel = MockPointOfSaleAggregateModel()
        let mockAnalytics = MockPOSAnalytics()
        let handler = POSItemActionHandlerFactory.itemActionHandler(
            itemListType: .products(search: true),
            searchTerm: "shoes",
            posModel: posModel,
            analytics: mockAnalytics
        )
        let item = makeProductItem()

        // When
        handler.handleTap(item)

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleAddItemToCart.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "product")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "search")
        #expect(event.properties[AnalyticsKeys.itemType] as? String == "product")
        #expect(event.properties[AnalyticsKeys.productType] as? String == "simple")
    }

    @available(iOS 17.0, *)
    @Test func coupons_search_tracks_correct_analytics() async throws {
        // Given
        let posModel = MockPointOfSaleAggregateModel()
        let mockAnalytics = MockPOSAnalytics()
        let handler = POSItemActionHandlerFactory.itemActionHandler(
            itemListType: .coupons(search: true),
            searchTerm: "discount",
            posModel: posModel,
            analytics: mockAnalytics
        )
        let item = makeCouponItem()

        // When
        handler.handleTap(item)

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleAddItemToCart.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "coupon")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "search")
        #expect(event.properties[AnalyticsKeys.itemType] as? String == "coupon")
        #expect(event.properties[AnalyticsKeys.productType] == nil)
    }

    @available(iOS 17.0, *)
    @Test func variation_list_tracks_correct_analytics() async throws {
        // Given
        let posModel = MockPointOfSaleAggregateModel()
        let mockAnalytics = MockPOSAnalytics()
        let handler = POSItemActionHandlerFactory.variationActionHandler(
            itemListType: .products(search: false),
            searchTerm: "",
            posModel: posModel,
            analytics: mockAnalytics
        )
        let item = makeVariationItem()

        // When
        handler.handleTap(item)

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleAddItemToCart.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "variation")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "list")
        #expect(event.properties[AnalyticsKeys.itemType] as? String == "product")
        #expect(event.properties[AnalyticsKeys.productType] as? String == "variation")
    }

    @available(iOS 17.0, *)
    @Test func variation_search_tracks_correct_analytics() async throws {
        // Given
        let posModel = MockPointOfSaleAggregateModel()
        let mockAnalytics = MockPOSAnalytics()
        let handler = POSItemActionHandlerFactory.variationActionHandler(
            itemListType: .products(search: true),
            searchTerm: "blue shirt",
            posModel: posModel,
            analytics: mockAnalytics
        )
        let item = makeVariationItem()

        // When
        handler.handleTap(item)

        // Then
        let event = try #require(mockAnalytics.events.first)
        #expect(event.eventName == WooAnalyticsStat.pointOfSaleAddItemToCart.rawValue)
        #expect(event.properties[AnalyticsKeys.source] as? String == "variation")
        #expect(event.properties[AnalyticsKeys.sourceType] as? String == "search")
        #expect(event.properties[AnalyticsKeys.itemType] as? String == "product")
        #expect(event.properties[AnalyticsKeys.productType] as? String == "variation")
    }
}

private func makeProductItem() -> POSItem {
    return .simpleProduct(.init(id: UUID(),
                                name: "Test",
                                formattedPrice: "$1.00",
                                productID: 1,
                                price: "1",
                                manageStock: false,
                                stockQuantity: nil,
                                stockStatusKey: ""))
}

private func makeCouponItem() -> POSItem {
    return .coupon(.init(id: UUID(), code: "DISCOUNT!"))
}

private func makeVariationItem() -> POSItem {
    return .variation(.init(
        id: .init(),
        name: "Test",
        formattedPrice: "$2.00",
        price: "2",
        productID: 2,
        variationID: 1,
        parentProductName: "")
    )
}
