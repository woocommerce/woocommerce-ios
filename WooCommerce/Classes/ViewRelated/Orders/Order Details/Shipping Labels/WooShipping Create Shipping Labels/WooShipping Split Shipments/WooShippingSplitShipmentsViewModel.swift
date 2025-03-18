import SwiftUI
import Yosemite
import WooFoundation

final class WooShippingSplitShipmentsViewModel: ObservableObject {
    private let order: Order
    private let stores: StoresManager
    private let config: WooShippingConfig

    /// Label for the total number of items
    let itemsCountLabel = "6 items"

    /// Label for the total item details
    let itemsDetailLabel = "825g  ·  $135.00"

    let items: [WooShippingItemRowViewModel] = [WooShippingItemRowViewModel(imageUrl: nil,
                                                                            quantityLabel: "3",
                                                                            name: "Little Nap Brazil 250g",
                                                                            detailsLabel: "15×10×8cm • Espresso",
                                                                            weightLabel: "275g",
                                                                            priceLabel: "$60.00"),
                                                WooShippingItemRowViewModel(imageUrl: nil,
                                                                            quantityLabel: "3",
                                                                            name: "Little Nap Brazil 250g",
                                                                            detailsLabel: "15×10×8cm • Espresso",
                                                                            weightLabel: "275g",
                                                                            priceLabel: "$60.00")]
    init(order: Order,
         config: WooShippingConfig,
         stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.config = config
        self.stores = stores
    }
}
