import Foundation
import enum Yosemite.POSItem
import enum Yosemite.POSItemType
import protocol WooFoundation.Analytics

/// Protocol for handling actions on POS items
@available(iOS 17.0, *)
protocol POSItemActionHandler {
    /// Handles a tap on an item
    /// - Parameter item: The item that was tapped
    func handleTap(_ item: POSItem)
}

@available(iOS 17.0, *)
extension POSItemActionHandler {
    /// Default implementation for analytics tracking
    /// - Parameter item: The item that was tapped
    /// - Parameter source: The source of the event
    /// - Parameter sourceType: The type of the source
    /// - Parameter using: The analytics service to track to
    func trackTapAnalytics(
        for item: POSItem,
        source: WooAnalyticsEvent.PointOfSale.Source,
        sourceType: WooAnalyticsEvent.PointOfSale.SourceType,
        using analytics: Analytics
    ) {
        switch item {
        case .simpleProduct:
            analytics.track(
                event: .PointOfSale.addItemToCart(
                    source: source,
                    sourceType: sourceType,
                    itemType: .product,
                    productType: .simple
                )
            )
        case .variation:
            analytics.track(
                event: .PointOfSale.addItemToCart(
                    source: source,
                    sourceType: sourceType,
                    itemType: .product,
                    productType: .variation
                )
            )
        case .coupon:
            analytics.track(
                event: .PointOfSale.addItemToCart(
                    source: source,
                    sourceType: sourceType,
                    itemType: .coupon
                )
            )
        default:
            break
        }
    }

    func shouldSkipDuplicate(_ item: POSItem, posModel: PointOfSaleAggregateModelProtocol) -> Bool {
        switch item {
        case .coupon:
            return posModel.cart.coupons.contains(where: { $0.id == item.id })
        default:
            return false
        }
    }
}

/// Standard handler for handling item taps without any special context
@available(iOS 17.0, *)
final class StandardPOSItemActionHandler: POSItemActionHandler {
    private let posModel: PointOfSaleAggregateModelProtocol
    private let source: WooAnalyticsEvent.PointOfSale.Source
    private let sourceType: WooAnalyticsEvent.PointOfSale.SourceType
    private let analytics: Analytics

    init(posModel: PointOfSaleAggregateModelProtocol,
         source: WooAnalyticsEvent.PointOfSale.Source,
         sourceType: WooAnalyticsEvent.PointOfSale.SourceType,
         analytics: Analytics = ServiceLocator.analytics
    ) {
        self.posModel = posModel
        self.source = source
        self.sourceType = sourceType
        self.analytics = analytics
    }

    func handleTap(_ item: POSItem) {
        if shouldSkipDuplicate(item, posModel: posModel) {
            return
        }
        posModel.addToCart(item)

        trackTapAnalytics(
            for: item,
            source: source,
            sourceType: sourceType,
            using: analytics
        )
    }
}

/// Handler for handling taps on search result items, saving the search term
@available(iOS 17.0, *)
final class SearchResultItemActionHandler: POSItemActionHandler {
    private let posModel: PointOfSaleAggregateModelProtocol
    private let searchTerm: String
    private let itemType: POSItemType
    private let source: WooAnalyticsEvent.PointOfSale.Source
    private let analytics: Analytics

    init(posModel: PointOfSaleAggregateModelProtocol,
         searchTerm: String,
         itemType: POSItemType,
         source: WooAnalyticsEvent.PointOfSale.Source,
         analytics: Analytics = ServiceLocator.analytics) {
        self.posModel = posModel
        self.searchTerm = searchTerm
        self.itemType = itemType
        self.source = source
        self.analytics = analytics
    }

    func handleTap(_ item: POSItem) {
        if shouldSkipDuplicate(item, posModel: posModel) {
            return
        }

        if searchTerm.isNotEmpty {
            posModel.saveSearchTerm(searchTerm, for: itemType)
        }

        posModel.addToCart(item)

        trackTapAnalytics(
            for: item,
            source: source,
            sourceType: searchTerm.isEmpty ? .preSearch : .search,
            using: analytics
        )
    }
}
