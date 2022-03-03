import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View Model logic for the Bulk Variations Update
final class BulkUpdateViewModel {

    typealias Section = BulkUpdateViewController.Section
    typealias Row = BulkUpdateViewController.Row

    /// Represents possible states for syncing product variations.
    enum SyncState: Equatable {
        case syncing
        case synced([Section])
        case error
        case notStarted
    }

    private let storageManager: StorageManagerType
    private let storesManager: StoresManager
    private let currencySettings: CurrencySettings
    private let siteID: Int64
    private let productID: Int64
    private var bulkUpdateFormModel = BulkUpdateOptionsModel(productVariations: [])
    private let currencyFormatter: CurrencyFormatter
    private var onCancelButtonTapped: () -> Void

    /// Product Variations Controller.
    ///
    private lazy var resultsController: ResultsController<StorageProductVariation> = {
        let predicate = NSPredicate(format: "siteID == %lld AND productID == %lld", siteID, productID)
        let resultsController = ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [])
        return resultsController
    }()

    private var sections: [Section] {
        guard bulkUpdateFormModel.productVariations.isNotEmpty else {
            return []
        }
        let priceSection = Section(title: Localization.priceSectionTitle, rows: [.regularPrice])

        return [priceSection]
    }

    /// The state of synching all variations
    @Published private(set) var syncState: SyncState

    init(siteID: Int64,
         productID: Int64,
         onCancelButtonTapped: @escaping () -> Void,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         storesManager: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = siteID
        self.productID = productID
        self.onCancelButtonTapped = onCancelButtonTapped
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
                guard let self = self else { return }

                if let error = error {
                    self.syncState = .error

                    DDLogError("⛔️ Error synchronizing product variations: \(error)")
                } else {
                    self.configureResultsControllerAndFetchData { [weak self] error in
                        guard let self = self else { return }

                        if error != nil {
                            self.syncState = .error
                        } else {
                            self.syncState = .synced(self.sections)
                        }
                    }
                }
            }

        storesManager.dispatch(action)
    }

    func handleTapCancel() {
        onCancelButtonTapped()
    }

    /// Provides the view model with all user facing data of the option for updating the regular price
    ///
    func viewModelForDisplayingRegularPrice() -> ValueOneTableViewCell.ViewModel {
        return ValueOneTableViewCell.ViewModel(text: Localization.updateRegularPriceTitle,
                                               detailText: detailTextforPrice(\ProductVariation.regularPrice))
    }

    /// Returns the detail text of the option for updating a price
    ///
    private func detailTextforPrice(_ priceKeyPath: KeyPath<ProductVariation, String?>) -> String {
        switch bulkUpdateFormModel.bulkValueOf(priceKeyPath) {
        case .none:
            return Localization.noneValue
        case .mixed:
            return Localization.mixedValue
        case let .value(price):
            return formatPriceString(price)
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
    private func configureResultsControllerAndFetchData(onCompletion: @escaping (Error?) -> Void) {
        resultsController.onDidChangeContent = { [weak self] in
            guard let self = self else { return }
            self.updateDataModel()
            onCompletion(nil)
        }

        do {
            try resultsController.performFetch()
            updateDataModel()
            onCompletion(nil)
        } catch {
            DDLogError("⛔️ Error fetching product variations: \(error)")
            onCompletion(error)
        }
    }

    /// When new data are available we should update them.
    ///
    private func updateDataModel() {
        // Limit the variations to `Constants.numberOfObjects`, since it is the limit of th bulk update API
        let candidatesForUpdate = Array(resultsController.fetchedObjects.prefix(Constants.numberOfObjects))
        bulkUpdateFormModel = BulkUpdateOptionsModel(productVariations: candidatesForUpdate)
    }
}

extension BulkUpdateViewModel {
    private enum Localization {
        static let priceSectionTitle = NSLocalizedString("Price",
                                                         comment: "The title for the price settings section in the product variation bulk update"
                                                         + "screen")
        static let mixedValue = NSLocalizedString("Mixed",
                                                  comment: "The description in product variations bulk update, of a value, that is different across"
                                                  + "all variations")
        static let noneValue = NSLocalizedString("None",
                                                 comment: "The description in product variations bulk update, of a value, that is missing from all variations")
        static let updateRegularPriceTitle = NSLocalizedString("Regular Price",
                                                               comment: "The label in the option of selecting to bulk update the regular price of a product"
                                                               + " variation")
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
