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
            return TitleAndEditableValueTableViewCell.self
        case .trackingNumber:
            return TitleAndEditableValueTableViewCell.self
        case .dateShipped:
            return TitleAndEditableValueTableViewCell.self
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


/// Abstracts the different viewmodels supporting adding, editing and creating custom
/// shipment trackings
///
protocol ManualTrackingViewModel {
    var siteID: Int { get }
    var orderID: Int { get }
    var orderStatus: String { get }
    var title: String { get }
    var providerCellName: String { get }
    var providerCellAccessoryType: UITableViewCell.AccessoryType { get }
    var primaryActionTitle: String { get }
    var secondaryActionTitle: String? { get }

    var sections: [AddEditTrackingSection] { get }
    var trackingNumber: String? { get set }
    var shipmentDate: Date { get set }
    var shipmentTracking: ShipmentTracking? { get }

    var shipmentProvider: ShipmentTrackingProvider? { get set }
    var shipmentProviderGroupName: String? { get set }

    var canCommit: Bool { get }
    var isCustom: Bool { get }
    var isAdding: Bool { get }

    func registerCells(for tableView: UITableView)
}

extension ManualTrackingViewModel {
    func registerCells(for tableView: UITableView) {
        for row in AddEditTrackingRow.allCases {
            tableView.register(row.type.loadNib(),
                               forCellReuseIdentifier: row.reuseIdentifier)
        }
    }
}


/// View model supporting adding shipment tacking manually, using non-custom providers
///
final class AddTrackingViewModel: ManualTrackingViewModel {
    let siteID: Int
    let orderID: Int
    let orderStatus: String

    let title = NSLocalizedString("Add Tracking",
                                 comment: "Add tracking screen - title.")

    let primaryActionTitle = NSLocalizedString("Add",
                                               comment: "Add tracking screen - button title to add a tracking")
    let secondaryActionTitle: String? = nil

    let shipmentTracking: ShipmentTracking? = nil

    var trackingNumber: String?

    var shipmentDate = Date()

    var sections: [AddEditTrackingSection] {
        let trackingRows: [AddEditTrackingRow] = [.shippingProvider,
                                                      .trackingNumber,
                                                      .dateShipped,
                                                      .datePicker]

        return [
            AddEditTrackingSection(rows: trackingRows)]

    }

    var shipmentProvider: ShipmentTrackingProvider? {
        didSet {
            saveSelectedShipmentProvider()
        }
    }

    var shipmentProviderGroupName: String?

    var providerCellName: String {
        return shipmentProvider?.name ?? ""
    }

    let providerCellAccessoryType = UITableViewCell.AccessoryType.disclosureIndicator

    var canCommit: Bool {
        return shipmentProvider != nil &&
            trackingNumber != nil
    }

    let isAdding: Bool = true

    let isCustom: Bool = false

    init(order: Order) {
        self.siteID = order.siteID
        self.orderID = order.orderID
        self.orderStatus = order.statusKey

        loadSelectedShipmentProvider()
    }

}


// MARK:- Persistence of the selected ShipmentTrackingProvider
//
private extension AddTrackingViewModel {
    func saveSelectedShipmentProvider() {
        guard let shipmentProvider = shipmentProvider else {
            return
        }

        let siteID = self.siteID

        let action = AppSettingsAction.addTrackingProvider(siteID: siteID, providerName: shipmentProvider.name) { error in
            guard let error = error else {
                return
            }

            DDLogError("⛔️ Save selected Tracking Provider Failure: [siteID = \(siteID)]. Error: \(error)")
        }

        StoresManager.shared.dispatch(action)
    }

    func loadSelectedShipmentProvider() {
        let siteID = self.siteID

        let action = AppSettingsAction.loadTrackingProvider(siteID: siteID) { [weak self] (provider, error) in
            guard let error = error else {
                self?.shipmentProvider = provider
                return
            }

            DDLogError("⛔️ Read selected Tracking Provider Failure: [siteID = \(siteID)]. Error: \(error)")
        }

        StoresManager.shared.dispatch(action)
    }
}

struct PreselectedProvider: Codable {
    private var siteID: Int
    private var providerName: String
}


/// View model supporting editing shipment tacking manually, using non-custom providers
///
final class EditTrackingViewModel: ManualTrackingViewModel {
    let siteID: Int
    let orderID: Int
    let orderStatus: String

    let title = NSLocalizedString("Edit Tracking",
                                 comment: "Edit tracking screen - title.")

    let primaryActionTitle = NSLocalizedString("Save",
                                               comment: "Edit tracking screen - button title to save a tracking")

    let secondaryActionTitle: String? = NSLocalizedString("Delete Tracking",
                                                 comment: "Delete Tracking button title")

    let shipmentTracking: ShipmentTracking?

    lazy var trackingNumber: String? = {
        return shipmentTracking?.trackingNumber
    }()

    lazy var shipmentDate: Date = {
        return shipmentTracking?.dateShipped ?? Date()
    }()

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

    let providerCellAccessoryType = UITableViewCell.AccessoryType.none

    var canCommit: Bool {
        return shipmentTracking?.trackingProvider != nil &&
            trackingNumber != nil
    }

    let isAdding: Bool = false

    var isCustom: Bool {
        return false
    }

    init(order: Order, shipmentTracking: ShipmentTracking) {
        self.siteID = order.siteID
        self.orderID = order.orderID
        self.orderStatus = order.statusKey
        self.shipmentTracking = shipmentTracking
    }
}
