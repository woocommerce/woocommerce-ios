import SwiftUI
import WooFoundation
import Yosemite

/// View model for `CollapsibleShipmentCard`.
final class CollapsibleShipmentCardViewModel: ObservableObject, Identifiable {
    let id = UUID()

    /// The main shipment row.
    let mainShipmentRow: SelectableShipmentRowViewModel

    /// Child shipment rows, if the shipment has more than one quantity
    let childShipmentRows: [SelectableShipmentRowViewModel]

    var onSelectionChange: (() -> Void)?

    var hasSelectedAnItem: Bool {
        if mainShipmentRow.selected {
            return true
        }

        return childShipmentRows
            .filter { $0.selected }
            .isNotEmpty
    }

    init(parentShipmentId: String,
         childShipmentIds: [String],
         item: ShippingLabelPackageItem,
         currency: String) {
        let mainShippingItem = WooShippingItemRowViewModel(item: ShippingLabelPackageItem(copy: item, quantity: max(1.0, Decimal(childShipmentIds.count))),
                                                           currency: currency)
        let childShippingItem = WooShippingItemRowViewModel(item: ShippingLabelPackageItem(copy: item, quantity: 1.0),
                                                            currency: currency)

        self.mainShipmentRow = SelectableShipmentRowViewModel(shipmentId: parentShipmentId,
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
        mainShipmentRow.setSelected(true)
        childShipmentRows.forEach({ $0.setSelected(true) })
        onSelectionChange?()
    }
}

private extension CollapsibleShipmentCardViewModel {
    func observeSelection() {
        mainShipmentRow.onSelectedChange = { [weak self] row in
            guard let self else { return }

            childShipmentRows.forEach({ $0.setSelected(row.selected) })
            onSelectionChange?()
        }

        childShipmentRows.forEach({
            $0.onSelectedChange = { [weak self] row in
                guard let self else { return }

                mainShipmentRow.setSelected(false)
                onSelectionChange?()
            }
        })
    }
}
