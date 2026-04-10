import SwiftUI
import WooFoundation
import Yosemite

/// View model for `CollapsibleShipmentItemCard`.
final class CollapsibleShipmentItemCardViewModel: ObservableObject, Identifiable {
    let id = UUID()

    let packageItem: ShippingLabelPackageItem

    /// The main item row.
    let mainItemRow: SelectableShipmentItemRowViewModel

    /// Child shipment rows, if the shipment has more than one quantity
    let childItemRows: [SelectableShipmentItemRowViewModel]

    var onSelectionChange: (() -> Void)?

    var numberOfSelectedItems: Int {
        if childItemRows.isEmpty {
            mainItemRow.selected ? 1 : 0
        } else {
            childItemRows.count { $0.selected }
        }
    }

    init(item: ShippingLabelPackageItem,
         isSelectable: Bool = true,
         currency: String) {
        self.packageItem = item

        let mainShippingItem = WooShippingItemRowViewModel(item: item,
                                                           currency: currency)
        let childShippingItem = WooShippingItemRowViewModel(item: ShippingLabelPackageItem(copy: item, quantity: 1.0),
                                                            currency: currency)

        self.mainItemRow = SelectableShipmentItemRowViewModel(itemID: "\(item.orderItemID)",
                                                              isSelectable: isSelectable,
                                                              item: mainShippingItem,
                                                              showQuantity: true)

        if item.quantity.intValue == 1 {
            self.childItemRows = []
        } else {
            var childItemRows = [SelectableShipmentItemRowViewModel]()
            for index in 0..<item.quantity.intValue {
                let childShipmentId = "\(item.orderItemID)-sub-\(index)"
                childItemRows.append(SelectableShipmentItemRowViewModel(itemID: childShipmentId,
                                                                        isSelectable: isSelectable,
                                                                        item: childShippingItem,
                                                                        showQuantity: false))
            }
            self.childItemRows = childItemRows
        }

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

                // Check if all child items are selected
                let allChildrenSelected = childItemRows.allSatisfy { $0.selected }
                mainItemRow.setSelected(allChildrenSelected)
                onSelectionChange?()
            }
        })
    }
}
