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
    case datePicker

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
        case .datePicker:
            return DatePickerTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

protocol ManualShipmentTrackingViewModel {
    var siteID: Int { get }
    var orderID: Int { get }
    var title: String { get }
    var providerCellName: String { get }
    var primaryActionTitle: String { get }
    var secondaryActionTitle: String? { get }

    var sections: [AddEditTrackingSection] { get }
    var trackingNumber: String? { get set }
    var shipmentDate: Date { get }
    var shipmentTracking: ShipmentTracking? { get }

    var shipmentProvider: ShipmentTrackingProvider? { get set }
    var shipmentProviderGroupName: String? { get set }

    var canCommit: Bool { get }
    var isCustom: Bool { get }
    var isAdding: Bool { get }

    func registerCells(for tableView: UITableView)
}

extension ManualShipmentTrackingViewModel {
    func registerCells(for tableView: UITableView) {
        for row in AddEditTrackingRow.allCases {
            tableView.register(row.type.loadNib(),
                               forCellReuseIdentifier: row.reuseIdentifier)
        }
    }
}

final class AddTrackingViewModel: ManualShipmentTrackingViewModel {
    let siteID: Int
    let orderID: Int

    let title = NSLocalizedString("Add Tracking",
                                 comment: "Add tracking screen - title.")

    let primaryActionTitle = NSLocalizedString("Add",
                                               comment: "Add tracking screen - button title to add a tracking")
    let secondaryActionTitle: String? = nil

    let shipmentTracking: ShipmentTracking? = nil

    var trackingNumber: String?

    let shipmentDate = Date()

    var sections: [AddEditTrackingSection] {
        let trackingRows: [AddEditTrackingRow] = [.shippingProvider,
                                                      .trackingNumber,
                                                      .dateShipped,
                                                      .datePicker]

        return [
            AddEditTrackingSection(rows: trackingRows)]

    }

    var shipmentProvider: ShipmentTrackingProvider?
    var shipmentProviderGroupName: String?

    var providerCellName: String {
        return shipmentProvider?.name ?? ""
    }

    var canCommit: Bool {
        return shipmentProvider != nil &&
            trackingNumber != nil
    }

    let isAdding: Bool = true

    var isCustom: Bool {
        return false
    }

    init(siteID: Int, orderID: Int) {
        self.siteID = siteID
        self.orderID = orderID
    }
}


final class EditTrackingViewModel: ManualShipmentTrackingViewModel {
    let siteID: Int
    let orderID: Int

    let title = NSLocalizedString("Edit Tracking",
                                 comment: "Edit tracking screen - title.")

    let primaryActionTitle = NSLocalizedString("Save",
                                               comment: "Edit tracking screen - button title to save a tracking")

    let secondaryActionTitle: String? = NSLocalizedString("Delete Tracking",
                                                 comment: "Delete Tracking button title")

    let shipmentTracking: ShipmentTracking?

    var trackingNumber: String?

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
    var shipmentProviderGroupName: String?

    var providerCellName: String {
        return shipmentTracking?.trackingProvider ?? ""
    }

    var canCommit: Bool {
        return shipmentTracking?.trackingProvider != nil &&
            trackingNumber != nil
    }

    let isAdding: Bool = false

    var isCustom: Bool {
        return false
    }

    init(siteID: Int, orderID: Int, shipmentTracking: ShipmentTracking) {
        self.siteID = siteID
        self.orderID = orderID
        self.shipmentTracking = shipmentTracking
    }
}
