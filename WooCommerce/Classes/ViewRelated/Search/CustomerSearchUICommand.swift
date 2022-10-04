import Yosemite

/// Implementation of `SearchUICommand` for Customer search
final class CustomerSearchUICommand: SearchUICommand {

    typealias ResultsControllerModel = StorageWCAnalyticsCustomer // Storage
    typealias Model = WCAnalyticsCustomer // Networking
    typealias CellViewModel = CustomerSearchViewModel // ViewModel

    let searchBarPlaceholder = NSLocalizedString("Search customers", comment: "Customers Search Placeholder")
    let searchBarAccessibilityIdentifier: String = "customer-search-screen-search-field"
    let cancelButtonAccessibilityIdentifier = "customer-search-screen-cancel-button"

    var resynchronizeModels: (() -> Void) = {}

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    func createResultsController() -> ResultsController<ResultsControllerModel> {
        let storageManager = ServiceLocator.storageManager // Access point to Core Data
        let predicate = NSPredicate(format: "", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController<StorageWCAnalyticsCustomer>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: [descriptor]
        )
    }

    func createStarterViewController() -> UIViewController? {
        nil
    }

    func createCellViewModel(model: WCAnalyticsCustomer) -> CustomerSearchViewModel {
        CustomerSearchViewModel(customer: model)
    }

    /// Synchronizes the Customers matching a given Keyword
    ///
    func synchronizeModels(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        // TODO:
        // let action = WCAnalyticsCustomerAction.searchCustomers(){ onCompletion?(result.isSuccess) }
        // stores.dispatch(action)
        // TODO:
        // analytics.track() -> Import Analytics into the init() as well.
    }

    func didSelectSearchResult(model: WCAnalyticsCustomer, from viewController: UIViewController, reloadData: () -> Void, updateActionButton: () -> Void) {
        // Should I create something like ProductDetailsFactory here?
    }

    func searchResultsPredicate(keyword: String) -> NSPredicate? {
        guard keyword.isNotEmpty else {
            return nil
        }
        // TODO:
        return NSPredicate(format: "TODO: Search results query", keyword)
    }
}
