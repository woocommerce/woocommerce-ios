import UIKit
import Foundation

struct AddEditTrackingSection {
    let rows: [AddEditTrackingRow]
}

enum AddEditTrackingRow: CaseIterable {
    case shippingProvider
    case trackingNumber
    case dateShipped
    case deleteTracking

    var type: UITableViewCell.Type {
        switch self {
        case .shippingProvider:
            return EditableValueOneTableViewCell.self
        case .trackingNumber:
            return EditableValueOneTableViewCell.self
        case .dateShipped:
            return EditableValueOneTableViewCell.self
        case .deleteTracking:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

protocol AddEditTrackingViewModel {
    var orderID: Int { get }
    var title: String { get }
    var primaryActionTitle: String { get }
    var secondaryActionTitle: String? { get }
    var sections: [AddEditTrackingSection] { get }

    func registerCells(for tableView: UITableView)
    func executeAction(for row: AddEditTrackingRow, sender: UIViewController)
}

extension AddEditTrackingViewModel {
    func registerCells(for tableView: UITableView) {
        for row in AddEditTrackingRow.allCases {
            tableView.register(row.type.loadNib(),
                               forCellReuseIdentifier: row.reuseIdentifier)
        }
    }
}

struct AddTrackingViewModel: AddEditTrackingViewModel {
    let orderID: Int

    let title = NSLocalizedString("Add Tracking",
                                 comment: "Add tracking screen - title.")

    let primaryActionTitle = NSLocalizedString("Add",
                                               comment: "Add tracking screen - button title to add a tracking")
    let secondaryActionTitle: String? = nil


    var sections: [AddEditTrackingSection] {
        let trackingRows: [AddEditTrackingRow] = [.shippingProvider,
                                                      .trackingNumber,
                                                      .dateShipped]

        return [
            AddEditTrackingSection(rows: trackingRows)]

    }

    func executeAction(for row: AddEditTrackingRow, sender: UIViewController) {
        if row == .shippingProvider {
            showAllShipmentProviders(sender: sender)
        }
    }

    private func showAllShipmentProviders(sender: UIViewController) {
        let shippingProviders = ShippingProvidersViewModel(orderID: orderID)
        let shippingList = ShippingProvidersViewController(viewModel: shippingProviders)
        sender.navigationController?.pushViewController(shippingList, animated: true)
    }
}


struct EditTrackingViewModel: AddEditTrackingViewModel {
    let orderID: Int

    let title = NSLocalizedString("Edit Tracking",
                                 comment: "Edit tracking screen - title.")

    let primaryActionTitle = NSLocalizedString("Save",
                                               comment: "Edit tracking screen - button title to save a tracking")

    let secondaryActionTitle: String? = NSLocalizedString("Delete Tracking",
                                                 comment: "Delete Tracking button title")

    var sections: [AddEditTrackingSection] {
        let trackingRows: [AddEditTrackingRow] = [.shippingProvider,
                                                      .trackingNumber,
                                                      .dateShipped]

        return [
            AddEditTrackingSection(rows: trackingRows),
            AddEditTrackingSection(rows: [.deleteTracking])]
    }

    func executeAction(for row: AddEditTrackingRow, sender: UIViewController) {
        if row == .deleteTracking {
            deleteCurrentTracking()
        }

        if row == .shippingProvider {
            showAllShipmentProviders(sender: sender)
        }
    }

    private func deleteCurrentTracking() {
        //
        print("=== ready to delete a shipment ===")
    }

    private func showAllShipmentProviders(sender: UIViewController) {
        let shippingProviders = ShippingProvidersViewModel(orderID: orderID)
        let shippingList = ShippingProvidersViewController(viewModel: shippingProviders)
        sender.navigationController?.pushViewController(shippingList, animated: true)
    }
}
