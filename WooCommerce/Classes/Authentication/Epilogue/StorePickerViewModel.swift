import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `StorePickerViewController`
///
final class StorePickerViewModel {
    /// Represents the internal StorePicker State
    ///
    @Published private(set) var state: StorePickerState = .empty

    /// ResultsController: Loads Sites from the Storage Layer.
    ///
    private lazy var resultsController: ResultsController<StorageSite> = {
        return ResultsController(storageManager: storageManager,
                                 sectionNameKeyPath: configuration.sectionNameKeyPath,
                                 matching: configuration.predicate,
                                 sortedBy: configuration.sortDescriptors)
    }()

    /// Selected configuration for the store picker
    ///
    private let configuration: StorePickerConfiguration

    private let storageManager: StorageManagerType
    private let stores: StoresManager
    private let analytics: Analytics

    init(configuration: StorePickerConfiguration,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.configuration = configuration
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
    }

    func trackScreenView() {
        let objects = resultsController.fetchedObjects
        let stores = objects.filter { $0.isWooCommerceActive == true }
        let nonWooSites = objects.filter { $0.isWooCommerceActive == false }
        analytics.track(.sitePickerStoresShown, withProperties: [
            "num_of_stores": stores.count,
            "number_of_non_woo_sites": nonWooSites.count
        ])
    }

    func refreshSites(currentlySelectedSiteID: Int64?) {
        refetchSitesAndUpdateState()

        synchronizeSites(selectedSiteID: currentlySelectedSiteID) { [weak self] _ in
            self?.refetchSitesAndUpdateState()
        }
    }
}

// MARK: - Private helpers
private extension StorePickerViewModel {
    func refetchSitesAndUpdateState() {
        try? resultsController.performFetch()
        state = StorePickerState(sites: resultsController.fetchedObjects)
    }

    func synchronizeSites(selectedSiteID: Int64?, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let syncStartTime = Date()
        let isJetpackConnectionPackageSupported = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.jetpackConnectionPackageSupport)
        let action = AccountAction
            .synchronizeSites(selectedSiteID: selectedSiteID,
                              isJetpackConnectionPackageSupported: isJetpackConnectionPackageSupported) { result in
                switch result {
                case .success(let containsJCPSites):
                    if containsJCPSites {
                        let syncDuration = round(Date().timeIntervalSince(syncStartTime) * 1000)
                        ServiceLocator.analytics.track(.jetpackCPSitesFetched, withProperties: ["duration": syncDuration])
                    }
                    onCompletion(.success(()))
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
        stores.dispatch(action)
    }
}

// MARK: - Table view configs
extension StorePickerViewModel {
    /// Indicates if there is more than one Store.
    ///
    var multipleStoresAvailable: Bool {
        return resultsController.fetchedObjects.count > 1
    }

    // Results Table's Separator Style
    ///
    var separatorStyle: UITableViewCell.SeparatorStyle {
        guard resultsController.numberOfObjects > 0 else {
            return .none
        }
        return .singleLine
    }

    /// Number of sections in the table view
    ///
    var numberOfSections: Int {
        guard resultsController.numberOfObjects > 0 else {
            return 1
        }
        return resultsController.sections.count
    }

    /// Title of the section at the specified index
    ///
    func titleForSection(at index: Int) -> String? {
        guard resultsController.numberOfObjects > 0 else {
            return nil
        }

        guard let rawStatus = resultsController.sections[safe: index]?.name else {
            return nil
        }

        let isWooCommerceActive = (rawStatus as NSString).boolValue
        if isWooCommerceActive {
            return multipleStoresAvailable ? Localization.pickStore : Localization.connectedStore
        } else {
            return Localization.otherSites
        }
    }

    /// Number of rows in a specified table view section index.
    ///
    func numberOfRows(inSection sectionIndex: Int) -> Int {
        guard resultsController.numberOfObjects > 0 else {
            return 1
        }
        return resultsController.sections[safe: sectionIndex]?.objects.count ?? 0
    }

    /// Returns the site to be displayed at a given IndexPath
    ///
    func site(at indexPath: IndexPath) -> Yosemite.Site? {
        guard resultsController.numberOfObjects > 0 else {
            return nil
        }
        return resultsController.safeObject(at: indexPath)
    }

    /// Returns the IndexPath for the specified Site.
    ///
    func indexPath(for siteID: Int64) -> IndexPath? {
        guard resultsController.numberOfObjects > 0 else {
            return nil
        }

        for (sectionIndex, section) in resultsController.sections.enumerated() {
            if let rowIndex = section.objects.firstIndex(where: { $0.siteID == siteID }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
}

private extension StorePickerViewModel {
    enum Localization {
        static let pickStore = NSLocalizedString(
            "Pick Store to Connect",
            comment: "Store Picker's Section Title: Displayed whenever there are multiple Stores.")
        static let connectedStore = NSLocalizedString(
            "Connected Store",
            comment: "Store Picker's Section Title: Displayed when there's a single pre-selected Store."
        )
        static let otherSites = NSLocalizedString(
            "Other Sites",
            comment: "Store Picker's Section Title: Displayed when there are sites without WooCommerce"
        )
    }
}

// MARK: - Extension to set up results controller for the store picker
//
private extension StorePickerConfiguration {
    var sectionNameKeyPath: String? {
        return "isWooCommerceActive"
    }

    var predicate: NSPredicate? {
        switch self {
        case .switchingStores:
            return NSPredicate(format: "isWooCommerceActive == YES")
        default:
            return nil
        }
    }

    var sortDescriptors: [NSSortDescriptor] {
        let nameDescriptor = NSSortDescriptor(keyPath: \StorageSite.name, ascending: true)
        let wooDescriptor = NSSortDescriptor(keyPath: \StorageSite.isWooCommerceActive, ascending: false)
        switch self {
        case .switchingStores:
            return [nameDescriptor]
        default:
            return [wooDescriptor, nameDescriptor]
        }
    }
}
