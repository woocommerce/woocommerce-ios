import Foundation

/// Provides view data for `WooShippingItemRow`.
///
struct WooShippingItemRowViewModel: Identifiable {
    /// Unique ID for the item row
    let id = UUID()

    /// URL for item image
    let imageUrl: URL?

    /// Label for item quantity
    let quantityLabel: String

    /// Item name
    let name: String

    /// Label for item details
    let detailsLabel: String

    /// Label for item weight
    let weightLabel: String

    /// Label for item price
    let priceLabel: String
}

/// Convenience extension to provide data to `WooShippingItemRow`
extension WooShippingItemRow {
    init(viewModel: WooShippingItemRowViewModel) {
        self.imageUrl = viewModel.imageUrl
        self.quantityLabel = viewModel.quantityLabel
        self.name = viewModel.name
        self.detailsLabel = viewModel.detailsLabel
        self.weightLabel = viewModel.weightLabel
        self.priceLabel = viewModel.priceLabel
    }
}
