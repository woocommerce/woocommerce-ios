import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View Model logic for the Bulk Variations Update
final class BulkUpdateViewModel {

    /// Represents possible states for syncing product variations.
    enum SyncState: Equatable {
        case syncing
        case syncedResults
        case syncingError
        case notStarted
    }

    private let storageManager: StorageManagerType
    private let storesManager: StoresManager
    private let siteID: Int64
    private let productID: Int64

    /// The state of synching all variations
    private(set) var syncState: SyncState {
        didSet {
            observeSyncState?(syncState)
        }
    }

    /// Called when syncing state changes
    var observeSyncState: ((SyncState) -> Void)?

    /// Product Variations Controller.
    ///
    private lazy var resultsController: ResultsController<StorageProductVariation> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let resultsController = ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [])

        return resultsController
    }()

    private var bulkUpdateFormDataModel: BulkUpdateFormDataModel?

    init(siteID: Int64,
         productID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         storesManager: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.productID = productID
        self.storageManager = storageManager
        self.storesManager = storesManager
        syncState = .notStarted
    }

    /// This is the main activation method for this view model.
    ///
    /// This should only be called when the corresponding view was loaded.
    /// 
    func activate() {
        synchAllProductVariations()
    }

    /// Start synching all product variations.
    ///
    func synchAllProductVariations() {
        syncState = .syncing

        let numberOfObjects = Constants.numberOfObjects
        // There is a limitof 100 objects for bulk update API, so we fetch 101 so see if user has more that 100.
        let pageNumber = Constants.pageNumber
        let action = ProductVariationAction
            .synchronizeProductVariations(siteID: siteID, productID: productID, pageNumber: pageNumber, pageSize: numberOfObjects) { [weak self] error in
                guard let self = self else {
                    return
                }

                if let error = error {
                    self.syncState = .syncingError

                    DDLogError("⛔️ Error synchronizing product variations: \(error)")
                }
                self.configureResultsController()
            }

        storesManager.dispatch(action)
    }

    /// Setup: Results Controller
    ///
    private func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            guard let self = self else {
                return
            }
            self.bulkUpdateFormDataModel = BulkUpdateFormDataModel(productVariations: self.resultsController.fetchedObjects)
            self.syncState = .syncedResults
        }

        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching product variations: \(error)")
        }
    }
}

extension BulkUpdateViewModel {

    private enum Constants {

        /// The page to be syched
        static let pageNumber = 1

        /// The bulk update API limits the objects to be update to 100. 100 is also the page limit.
        static let numberOfObjects = 100
    }
}

// Holds an array of product variations and provides caggregate data to for the bulk update form
///
final class BulkUpdateFormDataModel {

    /// The aggregate of a single value over all product variations
    ///
    enum BulkValue<T> {
        /// All variations have the same value
        case value(T)
        /// Variations have mixed values
        case mixed
//        case mixed(min: T, max: T)
        /// None of the variation has a value
        case none
    }

    let productVariations: [ProductVariation]

    init(productVariations: [ProductVariation]) {
        self.productVariations = productVariations
    }

    func regularPrice() -> BulkValue<String> {
        let results = productVariations.map(\.regularPrice).compactMap({ $0 }).uniqued()

        if let samePrice = results.first {
            return BulkValue.value(samePrice)
        } else if results.count != 1 {
            return BulkValue.mixed
        } else {
            return BulkValue.none
        }
    }

    func salePrice() -> BulkValue<String> {
        let results = productVariations.map(\.salePrice).compactMap({ $0 }).uniqued()

        if let samePrice = results.first {
            return BulkValue.value(samePrice)
        } else if results.count != 1 {
            return BulkValue.mixed
        } else {
            return BulkValue.none
        }
    }
}


