import SwiftUI
import WooFoundation
import Yosemite

/// View model for `CollapsibleShipmentItemCard`.
final class CollapsibleShipmentItemCardViewModel: ObservableObject, Identifiable {
    let id = UUID()

    /// The main item row.
    let mainItemRow: SelectableShipmentItemRowViewModel

    /// Child shipment rows, if the shipment has more than one quantity
    let childItemRows: [SelectableShipmentItemRowViewModel]

    var onSelectionChange: (() -> Void)?

    var selectedItemIds: [String] {
        if mainItemRow.selected {
            if childItemRows.isNotEmpty {
                return childItemRows.map { $0.itemID }
            } else {
                return [mainItemRow.itemID]
            }
        }

        return childItemRows
            .filter { $0.selected }
            .map(\.itemID)
    }

    init(parentShipmentId: String,
         childShipmentIds: [String],
         item: ShippingLabelPackageItem,
         currency: String) {
        let mainShippingItem = WooShippingItemRowViewModel(item: ShippingLabelPackageItem(copy: item, quantity: max(1.0, Decimal(childShipmentIds.count))),
                                                           currency: currency)
        let childShippingItem = WooShippingItemRowViewModel(item: ShippingLabelPackageItem(copy: item, quantity: 1.0),
                                                            currency: currency)

        self.mainItemRow = SelectableShipmentItemRowViewModel(itemID: parentShipmentId,
                                                              isSelectable: true,
                                                              item: mainShippingItem,
                                                              showQuantity: true)
        self.childItemRows = childShipmentIds.map({
            SelectableShipmentItemRowViewModel(itemID: $0,
                                               isSelectable: true,
                                               item: childShippingItem,
                                               showQuantity: false)
        })

        observeSelection()
    }

    func selectAll() {
        mainItemRow.setSelected(true)
        childItemRows.forEach({ $0.setSelected(true) })
        onSelectionChange?()
    }
}

private extension CollapsibleShipmentItemCardViewModel {
    func observeSelection() {
        mainItemRow.onSelectedChange = { [weak self] row in
            guard let self else { return }

            childItemRows.forEach({ $0.setSelected(row.selected) })
            onSelectionChange?()
        }

        childItemRows.forEach({
            $0.onSelectedChange = { [weak self] row in
                guard let self else { return }

                mainItemRow.setSelected(false)
                onSelectionChange?()
            }
        })
    }
}
