import Foundation
import UIKit
import Yosemite

/// Encapsulates the data necessary to render a list of shipment providers
///
final class ShippingProvidersViewModel {
    let order: Order

    /// Title of view displaying all available Shipment Tracking Providers
    let title = NSLocalizedString("Shipping Providers",
                                  comment: "Title of view displaying all available Shipment Tracking Providers")

    private let siteCountry = SiteCountry()
    private lazy var siteCountryName: String? = {
        return self.siteCountry.siteCountryName
    }()

    private var countryProviders: [StorageShipmentTrackingProvider] = []

    private lazy var predicateMatchingSiteCountry: NSPredicate? = {
        guard let name = self.siteCountryName else {
            return nil
        }

        return NSPredicate(format: "group.name contains[cd] %@",
                                    name)
    }()

    private lazy var predicateNotMatchingSiteCountry: NSPredicate? = {
        guard let name = self.siteCountryName else {
            return nil
        }

        return NSPredicate(format: "not group.name contains[cd] %@",
                                    name)
    }()


    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) StorageShipmentTrackingProviderGroup in sync.
    ///
    private lazy var resultsController: ResultsController<StorageShipmentTrackingProvider> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld",
                                    StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)

        let groupNameKeyPath = #keyPath(StorageShipmentTrackingProvider.group.name)
        let providerNameKeyPath = #keyPath(StorageShipmentTrackingProvider.name)

        let providerGroupDescriptor = NSSortDescriptor(key: groupNameKeyPath,
                                                      ascending: true)
        let providerNameDescriptor = NSSortDescriptor(key: providerNameKeyPath,
                                          ascending: true)

        return ResultsController<StorageShipmentTrackingProvider>(storageManager: storageManager,
                                                                       sectionNameKeyPath: groupNameKeyPath,
                                                                       matching: predicateExcludingStoreCountry(predicate: predicate),
                                                                       sortedBy: [providerGroupDescriptor, providerNameDescriptor])
    }()

    private lazy var storeCountryResultsController: ResultsController<StorageShipmentTrackingProvider> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld",
                                    StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)

        let groupNameKeyPath = #keyPath(StorageShipmentTrackingProvider.group.name)
        let providerNameKeyPath = #keyPath(StorageShipmentTrackingProvider.name)

        let providerGroupDescriptor = NSSortDescriptor(key: groupNameKeyPath,
                                                       ascending: true)
        let providerNameDescriptor = NSSortDescriptor(key: providerNameKeyPath,
                                                      ascending: true)

        return ResultsController<StorageShipmentTrackingProvider>(storageManager: storageManager,
                                                                  sectionNameKeyPath: groupNameKeyPath,
                                                                  matching: predicateMatchingStoreCountry(predicate: predicate),
                                                                  sortedBy: [providerGroupDescriptor, providerNameDescriptor])
    }()

    /// Closure to be executed when the data is ready to be rendered
    ///
    var onDataLoaded: (() -> Void)?

    /// Convenience property to check if the data collection is empty
    ///
    var isListEmpty: Bool {
        return resultsController.fetchedObjects.count == 0
    }

    /// Designated initializer
    ///
    init(order: Order) {
        self.order = order
    }

    /// Setup: Results Controller
    ///
    func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.dataWasUpdated()
        }

        resultsController.onDidResetContent = { [weak self] in
            self?.dataWasUpdated()
        }

        try? resultsController.performFetch()

        try? storeCountryResultsController.performFetch()
    }

    /// Filter results by text
    ///
    func filter(by text: String) {
        let predicate = NSPredicate(format: "name CONTAINS[cd] %@", text)
        //let predicate = predicateExcludingStoreCountry(predicate: NSPredicate(format: "name CONTAINS[cd] %@", text))
        resultsController.predicate = predicate
    }

    /// Clear all filters
    ///
    func clearFilters() {
        resultsController.predicate = nil
    }

    private func dataWasUpdated() {
        onDataLoaded?()
    }

    private func predicateExcludingStoreCountry(predicate: NSPredicate) -> NSPredicate {
        guard let excludingStore = predicateNotMatchingSiteCountry else {
            return predicate
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, excludingStore])
    }

    private func predicateMatchingStoreCountry(predicate: NSPredicate) -> NSPredicate {
        guard let matchingStore = predicateMatchingSiteCountry else {
            return predicate
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, matchingStore])
    }
}


// MARK: - Methods supporting an implementation of UITableViewDataSource
//
extension ShippingProvidersViewModel {
    func numberOfSections() -> Int {
        return resultsController.sections.count + Constants.specialSectionsCount
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        if section == Constants.customSectionIndex {
            return 1
        }

        if section ==  Constants.countrySectionIndex {
            let group = storeCountrySection()
            return group.objects.count
        }

        let group = resultsController.sections[section - Constants.specialSectionsCount]
        return group.objects.count
    }

    func titleForCellAt(_ indexPath: IndexPath) -> String {
        if indexPath.section == Constants.customSectionIndex {
            return Constants.customProvider
        }

        if indexPath.section == Constants.countrySectionIndex {
            let group = storeCountrySection()
            return group.objects[indexPath.item].name
            //return "Cesar"
        }

        let group = resultsController
            .sections[indexPath.section - Constants.specialSectionsCount]
        return group.objects[indexPath.item].name
    }

    func titleForHeaderInSection(_ section: Int) -> String {
        if section == Constants.customSectionIndex {
            return Constants.customGroup
        }

        if section == Constants.countrySectionIndex {
            return storeCountrySection().name
        }

        return resultsController
            .sections[section - Constants.specialSectionsCount]
            .name
    }

    private func storeCountrySection() -> ResultsController<StorageShipmentTrackingProvider>.SectionInfo {
        return storeCountryResultsController
            .sections[0]
    }
}


// MARK: - Methods supporting an implementation of UITableViewDataSource
//
extension ShippingProvidersViewModel {
    /// Indicates if the item at a given IndexPath is a custom shipment provider
    ///
    func isCustom(indexPath: IndexPath) -> Bool {
        return indexPath.section == Constants.customSectionIndex
    }

    /// Indicates the name of a group of shipment providers at a given IndexPath
    ///
    func groupName(at indexPath: IndexPath) -> String {
        if indexPath.section == Constants.countrySectionIndex {
            return storeCountryResultsController.sections[0].name
        }
        return resultsController.sections[indexPath.section - Constants.specialSectionsCount].name
    }

    /// Returns the ShipmentTrackingProvider at a given IndexPath
    ///
    func provider(at indexPath: IndexPath) -> ShipmentTrackingProvider {
        if indexPath.section == Constants.countrySectionIndex {
            let group = storeCountryResultsController.sections[0]
            let provider = group.objects[indexPath.item]

            return provider
        }

        let group = resultsController.sections[indexPath.section - Constants.specialSectionsCount]
        let provider = group.objects[indexPath.item]

        return provider
    }

    func shouldCreateCustomTracking(for groupName: String) -> Bool {
        return groupName == ShipmentStore.customGroupName
    }
}


private enum Constants {
    static let customSectionIndex = 0
    static let countrySectionIndex = 1
    static let specialSectionsCount = 2
    static let customGroup = NSLocalizedString("Custom",
                                               comment: "Name of the section for custom shipment tracking providers")
    static let customProvider = NSLocalizedString("Custom Provider",
                                                  comment: "Placeholder name of a custom shipment tracking provider")
}
