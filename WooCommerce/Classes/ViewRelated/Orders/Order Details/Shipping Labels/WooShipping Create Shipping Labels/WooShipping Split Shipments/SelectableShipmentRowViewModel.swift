import SwiftUI
import WooFoundation
import Yosemite

/// View model for `SelectableShipmentRow`.
final class SelectableShipmentRowViewModel: ObservableObject, Identifiable {
    let id = UUID()

    let item: WooShippingItemRowViewModel

    @Published private(set) var selected: Bool = false

    let isSelectable: Bool

    let shipmentId: String

    let showQuantity: Bool

    var onSelectedChange: ((SelectableShipmentRowViewModel) -> Void)?

    init(shipmentId: String,
         isSelectable: Bool,
         item: WooShippingItemRowViewModel,
         showQuantity: Bool = true) {
        self.shipmentId = shipmentId
        self.isSelectable = isSelectable
        self.item = item
        self.showQuantity = showQuantity
    }

    func handleTap() {
        selected = !selected
        if let onSelectedChange {
            onSelectedChange(self)
        }
    }

    func setSelected(_ selected: Bool) {
        self.selected = selected
    }
}
