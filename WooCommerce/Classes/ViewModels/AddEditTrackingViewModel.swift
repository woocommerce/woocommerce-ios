import UIKit
import Foundation
import Yosemite

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
    var providerCellName: String { get }
    var primaryActionTitle: String { get }
    var secondaryActionTitle: String? { get }
    var sections: [AddEditTrackingSection] { get }
    var shipmentDate: Date { get }
    var shipmentTracking: ShipmentTracking? { get }
    var shipmentProvider: ShipmentTrackingProvider? { get set }

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

final class AddTrackingViewModel: AddEditTrackingViewModel {
    let orderID: Int

    let title = NSLocalizedString("Add Tracking",
                                 comment: "Add tracking screen - title.")

    let primaryActionTitle = NSLocalizedString("Add",
                                               comment: "Add tracking screen - button title to add a tracking")
    let secondaryActionTitle: String? = nil

    let shipmentTracking: ShipmentTracking? = nil

    let shipmentDate = Date()

    var sections: [AddEditTrackingSection] {
        let trackingRows: [AddEditTrackingRow] = [.shippingProvider,
                                                      .trackingNumber,
                                                      .dateShipped]

        return [
            AddEditTrackingSection(rows: trackingRows)]

    }

    var shipmentProvider: ShipmentTrackingProvider?

    var providerCellName: String {
        return shipmentProvider?.name ?? ""
    }

    init(orderID: Int) {
        self.orderID = orderID
    }

    func executeAction(for row: AddEditTrackingRow, sender: UIViewController) {
        if row == .shippingProvider {
            showAllShipmentProviders(sender: sender)
        }

        if row == .dateShipped {
            showDatePicker(sender: sender)
        }
    }

    private func showAllShipmentProviders(sender: UIViewController) {
        let shippingProviders = ShippingProvidersViewModel(orderID: orderID)
        let shippingList = ShippingProvidersViewController(viewModel: shippingProviders, delegate: self)
        sender.navigationController?.pushViewController(shippingList, animated: true)
    }

    private func showDatePicker(sender: UIViewController) {
        PickerPresenter().showDatePicker(date: shipmentDate, sender: sender)
    }
}

extension AddTrackingViewModel: ShipmentProviderListDelegate {
    func shipmentProviderList(_ list: ShippingProvidersViewController, didSelect: ShipmentTrackingProvider) {
        shipmentProvider = didSelect
    }
}


final class EditTrackingViewModel: AddEditTrackingViewModel {
    let orderID: Int

    let title = NSLocalizedString("Edit Tracking",
                                 comment: "Edit tracking screen - title.")

    let primaryActionTitle = NSLocalizedString("Save",
                                               comment: "Edit tracking screen - button title to save a tracking")

    let secondaryActionTitle: String? = NSLocalizedString("Delete Tracking",
                                                 comment: "Delete Tracking button title")

    let shipmentTracking: ShipmentTracking?

    var shipmentDate: Date {
        return shipmentTracking?.dateShipped ?? Date()
    }

    var sections: [AddEditTrackingSection] {
        let trackingRows: [AddEditTrackingRow] = [.shippingProvider,
                                                      .trackingNumber,
                                                      .dateShipped]

        return [
            AddEditTrackingSection(rows: trackingRows),
            AddEditTrackingSection(rows: [.deleteTracking])]
    }

    var shipmentProvider: ShipmentTrackingProvider?

    var providerCellName: String {
        return shipmentProvider?.name ?? ""
    }

    init(orderID: Int, shipmentTracking: ShipmentTracking) {
        self.orderID = orderID
        self.shipmentTracking = shipmentTracking
    }

    func executeAction(for row: AddEditTrackingRow, sender: UIViewController) {
        if row == .deleteTracking {
            deleteCurrentTracking()
        }

        if row == .shippingProvider {
            showAllShipmentProviders(sender: sender)
        }

        if row == .dateShipped {
            showDatePicker(sender: sender)
        }
    }

    private func deleteCurrentTracking() {
        //
        print("=== ready to delete a shipment ===")
    }

    private func showAllShipmentProviders(sender: UIViewController) {
        let shippingProviders = ShippingProvidersViewModel(orderID: orderID)
        let shippingList = ShippingProvidersViewController(viewModel: shippingProviders, delegate: self)
        sender.navigationController?.pushViewController(shippingList, animated: true)
    }

    private func showDatePicker(sender: UIViewController) {
        PickerPresenter().showDatePicker(date: shipmentDate, sender: sender)
    }
}

extension EditTrackingViewModel: ShipmentProviderListDelegate {
    func shipmentProviderList(_ list: ShippingProvidersViewController, didSelect: ShipmentTrackingProvider) {
        shipmentProvider = didSelect
    }
}


private struct PickerPresenter {
    func showDatePicker(date: Date, sender: UIViewController) {
        let picker = UIDatePicker(frame: .zero)
        picker.autoresizingMask = .flexibleWidth
        picker.datePickerMode = .date
        picker.date = date
    }
}
