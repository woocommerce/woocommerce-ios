import Foundation
import enum Yosemite.POSItem
import protocol WooFoundation.Analytics

/// Protocol for handling actions on POS items
@available(iOS 17.0, *)
protocol POSItemActionHandler {
    /// Handles a tap on an item
    /// - Parameter item: The item that was tapped
    func handleTap(_ item: POSItem)
    /// Tracks analytics for a tap on an item
    /// - Parameter for: The item that was tapped
    /// - Parameter using: The analytics service to track to
    func trackTapAnalytics(for item: POSItem, using analytics: Analytics)
}

@available(iOS 17.0, *)
extension POSItemActionHandler {
    /// Default implementation for analytics tracking – it still needs to be called
    func trackTapAnalytics(for item: POSItem, using analytics: Analytics) {
        switch item {
        case .simpleProduct:
            analytics.track(event: .PointOfSale.addItemToCart(type: .simpleProduct))
        case .variation:
            analytics.track(event: .PointOfSale.addItemToCart(type: .variation))
        default:
            break
        }
    }
}

/// Standard handler for handling item taps without any special context
@available(iOS 17.0, *)
final class StandardPOSItemActionHandler: POSItemActionHandler {
    private let posModel: PointOfSaleAggregateModelProtocol
    private let analytics: Analytics

    init(posModel: PointOfSaleAggregateModelProtocol, analytics: Analytics = ServiceLocator.analytics) {
        self.posModel = posModel
        self.analytics = analytics
    }

    func handleTap(_ item: POSItem) {
        posModel.addToCart(item)

        trackTapAnalytics(for: item, using: analytics)
    }
}

/// Handler for handling taps on search result items, saving the search term
@available(iOS 17.0, *)
final class SearchResultItemActionHandler: POSItemActionHandler {
    private let posModel: PointOfSaleAggregateModelProtocol
    private let searchTerm: String
    private let itemType: ItemListType
    private let analytics: Analytics

    init(posModel: PointOfSaleAggregateModelProtocol, searchTerm: String, itemType: ItemListType, analytics: Analytics = ServiceLocator.analytics) {
        self.posModel = posModel
        self.searchTerm = searchTerm
        self.itemType = itemType
        self.analytics = analytics
    }

    func handleTap(_ item: POSItem) {
        posModel.saveSearchTerm(searchTerm, for: itemType)

        posModel.addToCart(item)
        trackTapAnalytics(for: item, using: analytics)
    }
}
