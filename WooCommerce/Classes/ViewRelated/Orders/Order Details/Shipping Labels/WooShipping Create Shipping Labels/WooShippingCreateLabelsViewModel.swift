import Foundation
import Yosemite

/// Provides view data for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewModel: ObservableObject {
    /// View model for the items to ship.
    @Published private(set) var items: WooShippingItemsViewModel

    /// Whether to mark the order as complete after the label is purchased.
    @Published var markOrderComplete: Bool = false

    /// Closure to execute after the label is successfully purchased.
    let onLabelPurchase: ((_ markOrderComplete: Bool) -> Void)?

    init(order: Order,
         onLabelPurchase: ((Bool) -> Void)? = nil) {
        self.items = WooShippingItemsViewModel(dataSource: DefaultWooShippingItemsDataSource(order: order))
        self.onLabelPurchase = onLabelPurchase
    }

    /// Purchases a shipping label with the provided label details and settings.
    func purchaseLabel() {
        // TODO: 13556 - Add action to purchase label remotely
        onLabelPurchase?(markOrderComplete) // TODO: 13556 - Only call this closure if the remote purchase is successful
    }
}
