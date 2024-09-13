import Foundation
import Yosemite

/// Provides view data for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewModel: ObservableObject {
    /// View model for the items to ship.
    @Published private(set) var items: WooShippingItemsViewModel

    init(order: Order) {
        self.items = WooShippingItemsViewModel(dataSource: DefaultWooShippingItemsDataSource(order: order))
    }
}
