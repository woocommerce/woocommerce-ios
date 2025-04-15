import Foundation
import enum Yosemite.POSItem
import protocol WooFoundation.Analytics

/// Protocol for handling actions on POS items
@available(iOS 17.0, *)
protocol POSItemActionHandler {
    /// Handles a tap on an item
    /// - Parameter item: The item that was tapped
    func handleTap(_ item: POSItem)
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

        trackTapAnalytics(for: item)
    }

    private func trackTapAnalytics(for item: POSItem) {
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
