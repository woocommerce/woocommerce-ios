import Foundation
import enum Yosemite.POSItem
import enum Yosemite.POSItemType
import protocol WooFoundation.Analytics
import struct WooFoundation.WooAnalyticsEvent

/// Protocol for handling actions on POS items
protocol POSItemActionHandler {
    /// Handles a tap on an item
    /// - Parameters:
    ///   - item: The item that was tapped
    ///   - position: The position of the item in the list (0-based), nil for non-search contexts
    func handleTap(_ item: POSItem, position: Int?)
}

extension POSItemActionHandler {
    /// Default implementation for analytics tracking
    func trackTapAnalytics(
        for item: POSItem,
        sourceView: WooAnalyticsEvent.PointOfSale.SourceView,
        sourceViewType: WooAnalyticsEvent.PointOfSale.SourceViewType,
        resultPosition: Int?,
        using analytics: POSAnalyticsProviding
    ) {
        switch item {
        case .simpleProduct:
            analytics.track(
                event: .PointOfSale.addItemToCart(
                    sourceView: sourceView,
                    sourceViewType: sourceViewType,
                    itemType: .product,
                    productType: .simple,
                    resultPosition: resultPosition
                )
            )
        case .variation, .searchResultVariation:
            analytics.track(
                event: .PointOfSale.addItemToCart(
                    sourceView: sourceView,
                    sourceViewType: sourceViewType,
                    itemType: .product,
                    productType: .variation,
                    resultPosition: resultPosition
                )
            )
        case .coupon:
            analytics.track(
                event: .PointOfSale.addItemToCart(
                    sourceView: sourceView,
                    sourceViewType: sourceViewType,
                    itemType: .coupon,
                    resultPosition: resultPosition
                )
            )
        default:
            break
        }
    }

    func shouldSkipDuplicate(_ item: POSItem, posModel: PointOfSaleAggregateModelProtocol) -> Bool {
        switch item {
        case .coupon:
            return posModel.cart.coupons.contains(where: { $0.posItemIdentifier == item.id })
        default:
            return false
        }
    }
}

/// Standard handler for handling item taps without any special context
final class StandardPOSItemActionHandler: POSItemActionHandler {
    private let posModel: PointOfSaleAggregateModelProtocol
    private let sourceView: WooAnalyticsEvent.PointOfSale.SourceView
    private let sourceViewType: WooAnalyticsEvent.PointOfSale.SourceViewType
    private let analytics: POSAnalyticsProviding

    init(posModel: PointOfSaleAggregateModelProtocol,
         sourceView: WooAnalyticsEvent.PointOfSale.SourceView,
         sourceViewType: WooAnalyticsEvent.PointOfSale.SourceViewType,
         analytics: POSAnalyticsProviding
    ) {
        self.posModel = posModel
        self.sourceView = sourceView
        self.sourceViewType = sourceViewType
        self.analytics = analytics
    }

    func handleTap(_ item: POSItem, position: Int?) {
        if shouldSkipDuplicate(item, posModel: posModel) {
            return
        }
        posModel.addToCart(item)

        trackTapAnalytics(
            for: item,
            sourceView: sourceView,
            sourceViewType: sourceViewType,
            resultPosition: nil,  // Standard handler doesn't track position
            using: analytics
        )
    }
}

/// Handler for handling taps on search result items, saving the search term
final class SearchResultItemActionHandler: POSItemActionHandler {
    private let posModel: PointOfSaleAggregateModelProtocol
    private let searchTerm: String
    private let itemType: POSItemType
    private let sourceView: WooAnalyticsEvent.PointOfSale.SourceView
    private let analytics: POSAnalyticsProviding

    init(posModel: PointOfSaleAggregateModelProtocol,
         searchTerm: String,
         itemType: POSItemType,
         sourceView: WooAnalyticsEvent.PointOfSale.SourceView,
         analytics: POSAnalyticsProviding) {
        self.posModel = posModel
        self.searchTerm = searchTerm
        self.itemType = itemType
        self.sourceView = sourceView
        self.analytics = analytics
    }

    func handleTap(_ item: POSItem, position: Int?) {
        if shouldSkipDuplicate(item, posModel: posModel) {
            return
        }

        if searchTerm.isNotEmpty {
            posModel.saveSearchTerm(searchTerm, for: itemType)
        }

        posModel.addToCart(item)

        let sourceViewType: WooAnalyticsEvent.PointOfSale.SourceViewType = searchTerm.isEmpty ? .preSearch : .search
        // Only include position for actual search results, not pre-search
        let resultPosition = sourceViewType == .search ? position : nil

        trackTapAnalytics(
            for: item,
            sourceView: sourceView,
            sourceViewType: sourceViewType,
            resultPosition: resultPosition,
            using: analytics
        )
    }
}

struct POSItemActionHandlerFactory {
    static func itemActionHandler(
        itemListType: ItemListType,
        searchTerm: String,
        posModel: PointOfSaleAggregateModelProtocol,
        analytics: POSAnalyticsProviding
    ) -> POSItemActionHandler {
        switch itemListType {
        case .products(search: false):
            StandardPOSItemActionHandler(posModel: posModel, sourceView: .product, sourceViewType: .list, analytics: analytics)
        case .coupons(search: false):
            StandardPOSItemActionHandler(posModel: posModel, sourceView: .coupon, sourceViewType: .list, analytics: analytics)
        case .products(search: true):
            SearchResultItemActionHandler(posModel: posModel, searchTerm: searchTerm, itemType: itemListType.itemType, sourceView: .product, analytics: analytics)
        case .coupons(search: true):
            SearchResultItemActionHandler(posModel: posModel, searchTerm: searchTerm, itemType: itemListType.itemType, sourceView: .coupon, analytics: analytics)
        }
    }

    static func variationActionHandler(
        itemListType: ItemListType,
        searchTerm: String,
        posModel: PointOfSaleAggregateModelProtocol,
        analytics: POSAnalyticsProviding
    ) -> POSItemActionHandler {
        if itemListType.isSearching {
            SearchResultItemActionHandler(
                posModel: posModel,
                searchTerm: searchTerm,
                itemType: itemListType.itemType,
                sourceView: .variation,
                analytics: analytics
            )
        } else {
            StandardPOSItemActionHandler(
                posModel: posModel,
                sourceView: .variation,
                sourceViewType: .list,
                analytics: analytics
            )
        }
    }
}
