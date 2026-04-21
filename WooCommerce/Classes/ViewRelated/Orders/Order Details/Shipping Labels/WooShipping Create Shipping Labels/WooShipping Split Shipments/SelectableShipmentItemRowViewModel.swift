import SwiftUI
import WooFoundation
import Yosemite

/// View model for `SelectableShipmentRow`.
final class SelectableShipmentItemRowViewModel: ObservableObject, Identifiable {
    let id = UUID()

    let item: WooShippingItemRowViewModel

    @Published private(set) var selected: Bool = false

    let isSelectable: Bool

    let itemID: String

    let showQuantity: Bool

    var onSelectedChange: ((SelectableShipmentItemRowViewModel) -> Void)?

    init(itemID: String,
         isSelectable: Bool,
         item: WooShippingItemRowViewModel,
         showQuantity: Bool = true) {
        self.itemID = itemID
        self.isSelectable = isSelectable
        self.item = item
        self.showQuantity = showQuantity
    }

    func handleTap() {
        selected.toggle()
        if let onSelectedChange {
            onSelectedChange(self)
        }
    }

    func setSelected(_ selected: Bool) {
        self.selected = selected
    }
}
