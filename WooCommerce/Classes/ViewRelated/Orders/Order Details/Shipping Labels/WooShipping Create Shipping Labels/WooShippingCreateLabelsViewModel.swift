import Foundation
import Yosemite

/// Provides view data for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewModel: ObservableObject {
    private let order: Order

    /// View model for the items to ship.
    @Published private(set) var items: WooShippingItemsViewModel

    init(order: Order) {
        self.order = order
        self.items = WooShippingItemsViewModel(order: order)
    }
}
