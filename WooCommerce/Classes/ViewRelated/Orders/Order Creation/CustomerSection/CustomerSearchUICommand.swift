import Foundation
import Yosemite

/// Implementation of `SearchUICommand` for Customer search.
///
final class CustomerSearchUICommand: SearchUICommand {

    typealias Model = Customer
    typealias CellViewModel = TitleAndSubtitleAndStatusTableViewCell.ViewModel
    typealias ResultsControllerModel = StorageCustomer

    var searchBarPlaceholder: String = Localization.searchBarPlaceHolder

    var searchBarAccessibilityIdentifier: String = "customer-search-screen-search-field"

    var cancelButtonAccessibilityIdentifier: String = "customer-search-screen-cancel-button"

    var resynchronizeModels: (() -> Void) = {}

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }

    func createResultsController() -> ResultsController<StorageCustomer> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageCustomer.customerID, ascending: false)
        return ResultsController<StorageCustomer>(storageManager: storageManager, sortedBy: [descriptor])
    }

    func createStarterViewController() -> UIViewController? {
        nil
    }

    func createCellViewModel(model: Customer) -> TitleAndSubtitleAndStatusTableViewCell.ViewModel {
        return CellViewModel(
            id: "\(model.customerID)",
            title: "\(model.firstName ?? "") \(model.lastName ?? ""))",
            subtitle: model.email,
            accessibilityLabel: "",
            status: "",
            statusBackgroundColor: .clear
        )
    }

    func synchronizeModels(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = CustomerAction.searchCustomers(siteID: siteID, keyword: keyword) { result in
            switch result {
            case .success(_):
                onCompletion?(result.isSuccess)
            case .failure(let error):
                DDLogError("Customer Search Failure \(error)")
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    func didSelectSearchResult(model: Customer, from viewController: UIViewController, reloadData: () -> Void, updateActionButton: () -> Void) {
        // Not implemented yet
        print("Selected ID: \(model.customerID) - Name: \(String(describing: model.firstName))")
    }

    func searchResultsPredicate(keyword: String) -> NSPredicate? {
        return NSPredicate(format: "ANY searchResults.keyword = %@", keyword)
    }
}

private extension CustomerSearchUICommand {
    enum Localization {
        static let searchBarPlaceHolder = NSLocalizedString("Search all customers",
                                                            comment: "Customer Search Placeholder")
    }
}
