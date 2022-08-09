import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `StorePickerViewController`
///
final class StorePickerViewModel {
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

    /// Storage manager
    ///
    private let storageManager: StorageManagerType

    init(configuration: StorePickerConfiguration,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.configuration = configuration
        self.storageManager = storageManager
    }

    func refreshSites() {
        try? resultsController.performFetch()
    }
}

// MARK: - Extension to set up results controller for the store picker
//
private extension StorePickerConfiguration {
    var sectionNameKeyPath: String? {
        switch self {
        case .switchingStores:
            return nil
        default:
            return "isWooCommerceActive"
        }
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
