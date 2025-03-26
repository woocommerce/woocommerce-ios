import SwiftUI
import WooFoundation
import Yosemite

/// View model for `CollapsibleShipmentCard`.
final class CollapsibleShipmentCardViewModel: ObservableObject, Identifiable {
    let id = UUID()

    /// The main item row.
    let mainItemRow: SelectableShipmentRowViewModel

    /// Child shipment rows, if the shipment has more than one quantity
    let childShipmentRows: [SelectableShipmentRowViewModel]

    var onSelectionChange: (() -> Void)?

    var selectedShipmentIds: [String] {
        if mainItemRow.selected {
            if childShipmentRows.isNotEmpty {
                return childShipmentRows.map { $0.shipmentId }
            } else {
                return [mainItemRow.shipmentId]
            }
        }

        return childShipmentRows
            .filter { $0.selected }
            .map(\.shipmentId)
    }

    init(parentShipmentId: String,
         childShipmentIds: [String],
         item: ShippingLabelPackageItem,
         currency: String) {
        let mainShippingItem = WooShippingItemRowViewModel(item: ShippingLabelPackageItem(copy: item, quantity: max(1.0, Decimal(childShipmentIds.count))),
                                                           currency: currency)
        let childShippingItem = WooShippingItemRowViewModel(item: ShippingLabelPackageItem(copy: item, quantity: 1.0),
                                                            currency: currency)

        self.mainItemRow = SelectableShipmentRowViewModel(shipmentId: parentShipmentId,
                                                          isSelectable: true,
                                                          item: mainShippingItem,
                                                          showQuantity: true)
        self.childShipmentRows = childShipmentIds.map({
            SelectableShipmentRowViewModel(shipmentId: $0,
                                           isSelectable: true,
                                           item: childShippingItem,
                                           showQuantity: false)
        })

        observeSelection()
    }

    func selectAll() {
        mainItemRow.setSelected(true)
        childShipmentRows.forEach({ $0.setSelected(true) })
        onSelectionChange?()
    }
}

private extension CollapsibleShipmentCardViewModel {
    func observeSelection() {
        mainItemRow.onSelectedChange = { [weak self] row in
            guard let self else { return }

            childShipmentRows.forEach({ $0.setSelected(row.selected) })
            onSelectionChange?()
        }

        childShipmentRows.forEach({
            $0.onSelectedChange = { [weak self] row in
                guard let self else { return }

                mainItemRow.setSelected(false)
                onSelectionChange?()
            }
        })
    }
}
