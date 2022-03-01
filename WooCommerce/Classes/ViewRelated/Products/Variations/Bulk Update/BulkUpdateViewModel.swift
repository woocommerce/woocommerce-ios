import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View Model logic for the Bulk Variations Update
final class BulkUpdateViewModel {

    typealias Section = BulkUpdateViewController.Section
    typealias Row = BulkUpdateViewController.Row

    /// Type that holds the description of an bulk update option, like "Mixed" or "None", and a flag indicating if the value is missing from all variations.
    typealias UpdateOptionDescription = (text: String, isNotSetForAll: Bool)

    /// Represents possible states for syncing product variations.
    enum SyncState: Equatable {
        case syncing
        case synced
        case error
        case notStarted
    }

    private let storageManager: StorageManagerType
    private let storesManager: StoresManager
    private let currencySettings: CurrencySettings
    private let siteID: Int64
    private let productID: Int64
    private var productVariations: [ProductVariation] = []
    private let currencyFormatter: CurrencyFormatter

    /// Product Variations Controller.
    ///
    private lazy var resultsController: ResultsController<StorageProductVariation> = {
        let predicate = NSPredicate(format: "siteID == %lld AND productID == %lld", siteID, productID)

        let resultsController = ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [])

        return resultsController
    }()

    /// The state of synching all variations
    @Published private(set) var syncState: SyncState

    var sections: [Section] {
        let priceSection = Section(title: Localization.priceTitle, rows: [.regularPrice])

        if productVariations.isEmpty {
            return []
        } else {
            return [priceSection]
        }
    }

    init(siteID: Int64,
         productID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         storesManager: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = siteID
        self.productID = productID
        self.storageManager = storageManager
        self.storesManager = storesManager
        self.currencySettings = currencySettings
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        syncState = .notStarted
    }

    /// This is the main activation method for this view model.
    ///
    /// This should only be called when the corresponding view was loaded.
    ///
    func activate() {
        synchProductVariations()
    }

    /// Start synching product variations. There is a limit of 100 objects that can be bulk updated.
    ///
    func synchProductVariations() {
        syncState = .syncing

        let numberOfObjects = Constants.numberOfObjects
        // There is a limitof 100 objects for bulk update API
        let pageNumber = Constants.pageNumber
        let action = ProductVariationAction
            .synchronizeProductVariations(siteID: siteID, productID: productID, pageNumber: pageNumber, pageSize: numberOfObjects) { [weak self] error in
                guard let self = self else {
                    return
                }

                if let error = error {
                    self.syncState = .error

                    DDLogError("⛔️ Error synchronizing product variations: \(error)")
                } else {
                    self.configureResultsController()
                }
            }

        storesManager.dispatch(action)
    }

    /// Provides the user facing details for the "bulk update option" of the sale price .
    /// It returns a tuple with the user facing text and a `Bool` indicating all of the variations do not have a value for the sale price.
    ///
    func regularPriceValue() -> UpdateOptionDescription {
        textforPrice(\ProductVariation.regularPrice)
    }

    /// It returns a tuple, containing a user facing description for the price of a collection of `ProductVariation`.
    /// The value is defined by the `priceKeyPath`.
    ///
    private func textforPrice(_ priceKeyPath: KeyPath<ProductVariation, String?>) -> UpdateOptionDescription {
        switch bulkValueOf(priceKeyPath) {
        case .none:
            return (BulkUpdateViewModel.Localization.noneValue, true)
        case .mixed:
            return (BulkUpdateViewModel.Localization.mixedValue, false)
        case let .value(price):
            return (formatPriceString(price), false)
        }
    }

    /// It formats a price `String` according to the current price settings.
    ///
    private func formatPriceString(_ price: String) -> String {
        let currencyCode = currencySettings.currencyCode
        let currency = currencySettings.symbol(from: currencyCode)

        return currencyFormatter.formatAmount(price, with: currency) ?? ""
    }

    /// Setup the results controller
    ///
    private func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            guard let self = self else {
                return
            }
            self.updateProductVariations()
        }

        do {
            try resultsController.performFetch()
            updateProductVariations()
        } catch {
            DDLogError("⛔️ Error fetching product variations: \(error)")
            syncState = .error
        }
    }

    /// When new data are available we should update them and then update the syncSate
    ///
    private func updateProductVariations() {
        productVariations = resultsController.fetchedObjects
        syncState = .synced
    }
}

extension BulkUpdateViewModel {
    private enum Localization {
        static let priceTitle = NSLocalizedString("Price", comment: "The title for the price settings section in the product variation bulk update screen")
        static let mixedValue = NSLocalizedString("Mixed",
                                                  comment: "The description in product variations bulk update, of a value, that is different across"
                                                    + "all variations")
        static let noneValue = NSLocalizedString("None",
                                                 comment: "The description in product variations bulk update, of a value, that is missing from all variations")
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

private extension BulkUpdateViewModel {
    /// Represents if a property in a collection of `ProductVariation`  has the same value or different values or is missing.
    ///
    enum BulkValue {
        /// All variations have the same value
        case value(String)
        /// When variations have mixed values.
        case mixed
        /// None of the variation has a value
        case none
    }

    /// Calculates and returns if a property, specified by a `ProductVariation` keypath , has the same value or different values or is missing
    /// over all product variations of this view model.
    ///
    func bulkValueOf(_ keypath: KeyPath<ProductVariation, String?>) -> BulkValue {
        let allValues = productVariations.prefix(Constants.numberOfObjects).map(keypath)
        let allValuesWithoutNilOrEmpty = allValues.compactMap { $0 }.filter { !$0.isEmpty }
        // filter all unique values that are not nil or empty
        let uniqueResults = allValuesWithoutNilOrEmpty.uniqued()

        if let samePrice = uniqueResults.first {
            if uniqueResults.count == 1 && allValues.count == allValuesWithoutNilOrEmpty.count {
                // If we have only 1 value and we did not had any nil/empty
                return BulkValue.value(samePrice)
            } else {
                // If at least ony value is different, even if it is missing (nil/empty)
                return BulkValue.mixed
            }
        } else {
            // If all values are missing or empty
            return BulkValue.none
        }
    }
}
