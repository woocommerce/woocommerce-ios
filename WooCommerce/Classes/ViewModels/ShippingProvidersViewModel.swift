import Foundation
import UIKit
import Yosemite

/// Encapsulates the logic necessary to render a list of shipment tracking providers
/// The list of providers has to be ordered alphabetically (ascending), wiht two exceptions:
/// - A section to add Custom Providers
/// - The providers corresponding to the store country should be shown first
final class ShippingProvidersViewModel {
    let order: Order

    /// Title of view displaying all available Shipment Tracking Providers
    let title = NSLocalizedString("Shipping Providers",
                                  comment: "Title of view displaying all available Shipment Tracking Providers")

    /// The currently selected tracking provider.
    private let selectedProvider: ShipmentTrackingProvider?
    /// The currently selected tracking provider's group name.
    private let selectedProviderGroupName: String?

    // MARK: - Store country

    /// Encapsulates the logic to figure out the current store's country
    /// and translate that into a readable string
    private let siteCountry = SiteCountry()

    /// The name of the current store's country
    private lazy var siteCountryName: String? = {
        return self.siteCountry.siteCountryName
    }()

    // MARK: - Predicates

    /// Predicate to match all the providers that correspond
    /// to the store's country
    private lazy var predicateMatchingSiteCountry: NSPredicate? = {
        guard let name = self.siteCountryName else {
            return nil
        }

        return NSPredicate(format: "group.name contains[cd] %@",
                                    name)
    }()

    /// Predicate to match all the providers excluding those matching
    /// the store's country
    private lazy var predicateNotMatchingSiteCountry: NSPredicate? = {
        guard let name = self.siteCountryName else {
            return nil
        }

        return NSPredicate(format: "not group.name contains[cd] %@",
                                    name)
    }()

    // MARK: - Results controllers

    /// ResultsController to fetch the list of shipment providers,
    /// excluding the store country
    private lazy var providersExcludingStoreCountry: ResultsController<StorageShipmentTrackingProvider> = {
        let storageManager = ServiceLocator.storageManager
        let groupNameKeyPath = ResultsControllerConstants.groupNameKeyPath
        let providerNameKeyPath = ResultsControllerConstants.providerNameKeyPath
        let excludingStoreCountry = predicateExcludingStoreCountry(predicate: ResultsControllerConstants.predicateForAllProviders)

        let providerGroupDescriptor = NSSortDescriptor(key: groupNameKeyPath,
                                                      ascending: true)
        let providerNameDescriptor = NSSortDescriptor(key: providerNameKeyPath,
                                          ascending: true)

        return ResultsController<StorageShipmentTrackingProvider>(storageManager: storageManager,
                                                                       sectionNameKeyPath: groupNameKeyPath,
                                                                       matching: excludingStoreCountry,
                                                                       sortedBy: [providerGroupDescriptor, providerNameDescriptor])
    }()

    /// Results controller, to fetch the list of shipment providers
    /// correspoding to the store country
    private lazy var providersForStoreCountry: ResultsController<StorageShipmentTrackingProvider> = {
        let storageManager = ServiceLocator.storageManager
        let groupNameKeyPath = ResultsControllerConstants.groupNameKeyPath
        let providerNameKeyPath = ResultsControllerConstants.providerNameKeyPath

        let matchingStoreCountry = predicateMatchingStoreCountry(predicate: ResultsControllerConstants.predicateForAllProviders)

        let providerGroupDescriptor = NSSortDescriptor(key: groupNameKeyPath,
                                                       ascending: true)
        let providerNameDescriptor = NSSortDescriptor(key: providerNameKeyPath,
                                                      ascending: true)

        return ResultsController<StorageShipmentTrackingProvider>(storageManager: storageManager,
                                                                  sectionNameKeyPath: groupNameKeyPath,
                                                                  matching: matchingStoreCountry,
                                                                  sortedBy: [providerGroupDescriptor, providerNameDescriptor])
    }()

    /// Closure to be executed when the data is ready to be rendered
    ///
    var onDataLoaded: (() -> Void)?

    /// Convenience property to check if the data collection is empty
    ///
    var isListEmpty: Bool {
        return providersExcludingStoreCountry.fetchedObjects.count == 0
    }

    private var storeCountryHasProviders: Bool {
        return providersForStoreCountry.fetchedObjects.count != 0
    }

    /// Designated initializer
    ///
    init(order: Order, selectedProvider: ShipmentTrackingProvider?, selectedProviderGroupName: String?) {
        self.order = order
        self.selectedProvider = selectedProvider
        self.selectedProviderGroupName = selectedProviderGroupName
    }

    /// Setup: Results Controller
    ///
    func configureResultsController() {
        providersExcludingStoreCountry.onDidChangeContent = { [weak self] in
            self?.dataWasUpdated()
        }

        providersExcludingStoreCountry.onDidResetContent = { [weak self] in
            self?.dataWasUpdated()
        }

        try? providersExcludingStoreCountry.performFetch()

        providersForStoreCountry.onDidChangeContent = { [weak self] in
            self?.dataWasUpdated()
        }

        providersForStoreCountry.onDidResetContent = { [weak self] in
            self?.dataWasUpdated()
        }

        try? providersForStoreCountry.performFetch()
    }

    /// Filter results by text
    ///
    func filter(by text: String) {
        let nameFilter = NSPredicate(format: "name CONTAINS[cd] %@", text)
        providersExcludingStoreCountry.predicate = predicateExcludingStoreCountry(predicate: nameFilter)
        providersForStoreCountry.predicate = predicateMatchingStoreCountry(predicate: nameFilter)
    }

    /// Clear all filters
    ///
    func clearFilters() {
        providersExcludingStoreCountry.predicate =
            predicateExcludingStoreCountry(predicate: ResultsControllerConstants.predicateForAllProviders)
        providersForStoreCountry.predicate =
            predicateMatchingStoreCountry(predicate: ResultsControllerConstants.predicateForAllProviders)
    }

    private func dataWasUpdated() {
        onDataLoaded?()
    }
}


// MARK: - Support for composing predicates
extension ShippingProvidersViewModel {
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


// MARK: - Methods supporting the implementation of UITableViewDataSource
//
extension ShippingProvidersViewModel {
    func numberOfSections() -> Int {
        return providersExcludingStoreCountry.sections.count + delta()
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        if !storeCountryHasProviders &&
            section == 0 {
            return 1
        }

        if storeCountryHasProviders &&
            section == Constants.customSectionIndex {
            return 1
        }

        if storeCountryHasProviders &&
            section ==  Constants.countrySectionIndex {
            let group = storeCountrySection()
            return group?.objects.count ?? 0
        }

        let group = providersExcludingStoreCountry.sections[section - delta()]
        return group.objects.count
    }

    func titleForCellAt(_ indexPath: IndexPath) -> String {
        if !storeCountryHasProviders &&
            indexPath.section == 0 {
            return Constants.customProvider
        }

        if storeCountryHasProviders &&
            indexPath.section == Constants.customSectionIndex {
            return Constants.customProvider
        }

        if storeCountryHasProviders &&
            indexPath.section == Constants.countrySectionIndex {
            let group = storeCountrySection()
            return group?.objects[indexPath.item].name ?? ""
        }

        let group = providersExcludingStoreCountry
            .sections[indexPath.section - delta()]
        return group.objects[indexPath.item].name
    }

    func titleForHeaderInSection(_ section: Int) -> String {
        if !storeCountryHasProviders &&
            section == 0 {
            return Constants.customGroup
        }

        if storeCountryHasProviders &&
            section == Constants.customSectionIndex {
            return Constants.customGroup
        }

        if storeCountryHasProviders &&
            section == Constants.countrySectionIndex {
            return storeCountrySection()?.name ?? ""
        }

        return providersExcludingStoreCountry
            .sections[section - delta()]
            .name
    }

    private func storeCountrySection() -> ResultsController<StorageShipmentTrackingProvider>.SectionInfo? {
        return providersForStoreCountry
            .sections.first
    }

    private func delta() -> Int {
        return storeCountryHasProviders ? Constants.specialSectionsCount : Constants.specialSectionsCount - 1
    }
}


// MARK: - Methods supporting the implementation of UITableViewDataSource
//
extension ShippingProvidersViewModel {
    /// Indicates if the item at a given IndexPath is a custom shipment provider
    ///
    func isCustom(indexPath: IndexPath) -> Bool {
        if !storeCountryHasProviders {
            return indexPath.section == 0
        }

        return indexPath.section == Constants.customSectionIndex
    }

    /// Indicates the name of a group of shipment providers at a given IndexPath
    ///
    func groupName(at indexPath: IndexPath) -> String? {
        if storeCountryHasProviders &&
            indexPath.section == Constants.countrySectionIndex {
            return storeCountrySection()?.name
        }
        return providersExcludingStoreCountry.sections[safe: indexPath.section - delta()]?.name
    }

    /// Returns the ShipmentTrackingProvider at a given IndexPath
    ///
    func provider(at indexPath: IndexPath) -> ShipmentTrackingProvider? {
        if storeCountryHasProviders &&
            indexPath.section == Constants.countrySectionIndex {
            let group = storeCountrySection()
            let provider = group?.objects[indexPath.item]

            return provider
        }

        guard let group = providersExcludingStoreCountry.sections[safe: indexPath.section - delta()] else {
            return nil
        }

        let provider = group.objects[indexPath.item]

        return provider
    }

    func shouldCreateCustomTracking(for groupName: String) -> Bool {
        return groupName == ShipmentStore.customGroupName
    }
}


// MARK: - Constants
//
private enum ResultsControllerConstants {
    static let predicateForAllProviders =
        NSPredicate(format: "siteID == %lld",
                    ServiceLocator.stores.sessionManager.defaultStoreID ?? Int.min)
    static let groupNameKeyPath =
        #keyPath(StorageShipmentTrackingProvider.group.name)
    static let providerNameKeyPath = #keyPath(StorageShipmentTrackingProvider.name)
}

private enum Constants {
    static let countrySectionIndex = 0
    static let customSectionIndex = 1
    static let specialSectionsCount = 2
    static let customGroup = NSLocalizedString("Custom",
                                               comment: "Name of the section for custom shipment tracking providers")
    static let customProvider = NSLocalizedString("Custom Provider",
                                                  comment: "Placeholder name of a custom shipment tracking provider")
}
