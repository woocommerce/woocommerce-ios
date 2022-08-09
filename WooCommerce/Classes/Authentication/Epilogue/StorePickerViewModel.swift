import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `StorePickerViewController`
///
final class StorePickerViewModel {
    /// ResultsController: Loads Sites from the Storage Layer.
    ///
    private lazy var resultsController: ResultsController<StorageSite> = {
        let predicate = NSPredicate(format: "isWooCommerceActive == YES")
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
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
}
