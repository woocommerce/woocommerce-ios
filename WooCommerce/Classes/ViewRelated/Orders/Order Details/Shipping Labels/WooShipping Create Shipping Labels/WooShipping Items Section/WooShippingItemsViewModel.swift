import Foundation

/// Provides view data for `WooShippingItems`.
///
struct WooShippingItemsViewModel {
    /// Label for the total number of items
    let itemsCountLabel: String

    /// Label for the total item details
    let itemsDetailLabel: String

    /// View models for items to ship
    let items: [WooShippingItemRowViewModel]
}

/// Convenience extension to provide data to `WooShippingItemRow`
extension WooShippingItems {
    init(viewModel: WooShippingItemsViewModel) {
        self.itemsCountLabel = viewModel.itemsCountLabel
        self.itemsDetailLabel = viewModel.itemsDetailLabel
        self.items = viewModel.items
    }
}
