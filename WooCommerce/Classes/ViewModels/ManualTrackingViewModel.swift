import UIKit
import Foundation
import Yosemite

// MARK: - Sections
struct AddEditTrackingSection {
    let rows: [AddEditTrackingRow]
}

enum AddEditTrackingRow: CaseIterable {
    case shippingProvider
    case providerName
    case trackingNumber
    case trackingLink
    case dateShipped
    case deleteTracking
    case datePicker

    var type: UITableViewCell.Type {
        switch self {
        case .shippingProvider:
            return TitleAndEditableValueTableViewCell.self
        case .providerName:
            return TitleAndEditableValueTableViewCell.self
        case .trackingNumber:
            return TitleAndEditableValueTableViewCell.self
        case .trackingLink:
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


// MARK: - View Model Protocol

/// Abstracts the different viewmodels supporting adding, editing and creating custom
/// shipment trackings
///
protocol ManualTrackingViewModel {
    var order: Order { get }
    var title: String { get }
    var providerCellName: String { get }
    var providerCellAccessoryType: UITableViewCell.AccessoryType { get }
    var primaryActionTitle: String { get }
    var secondaryActionTitle: String? { get }

    var sections: [AddEditTrackingSection] { get }
    var providerName: String? { get set }
    var trackingNumber: String? { get set }
    var trackingLink: String? { get set }
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


// MARK: - ViewModel for adding a tracking provider

/// View model supporting adding shipment tacking manually, using non-custom providers
///
final class AddTrackingViewModel: ManualTrackingViewModel {
    let order: Order

    let title = NSLocalizedString("Add Tracking",
                                 comment: "Add tracking screen - title.")

    let primaryActionTitle = NSLocalizedString("Add",
                                               comment: "Add tracking screen - button title to add a tracking")
    let secondaryActionTitle: String? = nil

    let shipmentTracking: ShipmentTracking? = nil

    var providerName: String?

    var trackingNumber: String?

    var trackingLink: String?

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
            trackingNumber?.isEmpty == false
    }

    let isAdding: Bool = true

    let isCustom: Bool = false

    init(order: Order) {
        self.order = order

        loadSelectedShipmentProvider()
    }
}


// MARK: - Persistence of the selected ShipmentTrackingProvider
//
private extension AddTrackingViewModel {
    func saveSelectedShipmentProvider() {
        guard let shipmentProvider = shipmentProvider else {
            return
        }

        let siteID = order.siteID

        let action = AppSettingsAction.addTrackingProvider(siteID: siteID, providerName: shipmentProvider.name) { error in
            guard let error = error else {
                return
            }

            DDLogError("⛔️ Save selected Tracking Carrier Failure: [siteID = \(siteID)]. Error: \(error)")
        }

        ServiceLocator.stores.dispatch(action)
    }

    func loadSelectedShipmentProvider() {
        let siteID = order.siteID

        let action = AppSettingsAction.loadTrackingProvider(siteID: siteID) { [weak self] (provider, providerGroup, error) in
            guard let error = error else {
                self?.shipmentProvider = provider
                self?.shipmentProviderGroupName = providerGroup?.name
                return
            }

            DDLogError("⛔️ Read selected Tracking Carrier Failure: [siteID = \(siteID)]. Error: \(error)")
        }

        ServiceLocator.stores.dispatch(action)
    }
}


// MARK: - ViewModel for adding a custom tracking provider

/// View model supporting adding custom shipment tacking manually, using non-custom providers
///
final class AddCustomTrackingViewModel: ManualTrackingViewModel {
    let order: Order

    let title = NSLocalizedString("Add Tracking",
                                  comment: "Add tracking screen - title.")

    let primaryActionTitle = NSLocalizedString("Add",
                                               comment: "Add tracking screen - button title to add a tracking")
    let secondaryActionTitle: String? = nil

    let shipmentTracking: ShipmentTracking? = nil

    var providerName: String?

    var trackingNumber: String?

    var trackingLink: String?

    var shipmentDate = Date()

    var sections: [AddEditTrackingSection] {
        let trackingRows: [AddEditTrackingRow] = [.shippingProvider,
                                                  .providerName,
                                                  .trackingNumber,
                                                  .trackingLink,
                                                  .dateShipped,
                                                  .datePicker]

        return [
            AddEditTrackingSection(rows: trackingRows)]

    }

    var shipmentProvider: ShipmentTrackingProvider?

    var shipmentProviderGroupName: String?

    var providerCellName: String {
        return NSLocalizedString("Custom Carrier", comment: "Add custom shipping carrier. Content of cell titled Shipping Carrier")
    }

    let providerCellAccessoryType = UITableViewCell.AccessoryType.none

    var canCommit: Bool {
        let returnValue = providerName?.isEmpty == false &&
            trackingNumber?.isEmpty == false

        if returnValue {
            saveSelectedCustomShipmentProvider()
        }

        return returnValue
    }

    let isAdding: Bool = true

    let isCustom: Bool = true

    init(order: Order, initialName: String? = nil) {
        self.order = order
        self.providerName = initialName

        // if we don't have a provider name, try to load a previous one
        guard let providerName = self.providerName,
            !providerName.isEmpty else {
                loadSelectedCustomShipmentProvider()
                return
        }
    }
}


private extension AddCustomTrackingViewModel {
    func saveSelectedCustomShipmentProvider() {
        guard let providerName = providerName else {
            return
        }

        let siteID = order.siteID

        let action = AppSettingsAction.addCustomTrackingProvider(siteID: siteID, providerName: providerName, providerURL: trackingLink) { error in
            guard let error = error else {
                return
            }

            DDLogError("⛔️ Save selected Custom Tracking Carrier Failure: [siteID = \(siteID)]. Error: \(error)")
        }

        ServiceLocator.stores.dispatch(action)
    }

    func loadSelectedCustomShipmentProvider() {
        let siteID = order.siteID

        let action = AppSettingsAction.loadCustomTrackingProvider(siteID: siteID) { [weak self] (provider, error) in
            guard let error = error else {
                self?.providerName = provider?.name
                self?.trackingLink = provider?.url
                return
            }

            DDLogError("⛔️ Read selected Custom Tracking Carrier Failure: [siteID = \(siteID)]. Error: \(error)")
        }

        ServiceLocator.stores.dispatch(action)
    }
}
