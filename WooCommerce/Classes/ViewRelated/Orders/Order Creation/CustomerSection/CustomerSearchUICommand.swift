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

    var onDidSelectSearchResult: ((Customer) -> Void)

    private let siteID: Int64

    init(siteID: Int64, onDidSelectSearchResult: @escaping ((Customer) -> Void)) {
        self.siteID = siteID
        self.onDidSelectSearchResult = onDidSelectSearchResult
    }

    func createResultsController() -> ResultsController<StorageCustomer> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageCustomer.customerID, ascending: false)
        return ResultsController<StorageCustomer>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }

    func createStarterViewController() -> UIViewController? {
        nil
    }

    func createCellViewModel(model: Customer) -> TitleAndSubtitleAndStatusTableViewCell.ViewModel {
        return CellViewModel(
            id: "\(model.customerID)",
            title: "\(model.firstName ?? "") \(model.lastName ?? "")",
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
        print("1 - Customer tapped")
        print("2 - Customer ID: \(model.customerID) - Name: \(model.firstName ?? ""))")
        // Customer data will go up to EditOrderAddressForm, via OrderCustomerListView completion handler
        onDidSelectSearchResult(model)
    }

    func searchResultsPredicate(keyword: String) -> NSPredicate? {
        return NSPredicate(format: "siteID == %lld AND ANY searchResults.keyword = %@", siteID, keyword)
    }
}

private extension CustomerSearchUICommand {
    enum Localization {
        static let searchBarPlaceHolder = NSLocalizedString("Search all customers",
                                                            comment: "Customer Search Placeholder")
    }
}
