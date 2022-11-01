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

    private let analytics: Analytics

    init(siteID: Int64,
         analytics: Analytics = ServiceLocator.analytics,
         onDidSelectSearchResult: @escaping ((Customer) -> Void)) {
        self.siteID = siteID
        self.analytics = analytics
        self.onDidSelectSearchResult = onDidSelectSearchResult
    }

    func createResultsController() -> ResultsController<StorageCustomer> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageCustomer.customerID, ascending: false)
        return ResultsController<StorageCustomer>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }

    func createStarterViewController() -> UIViewController? {
        createEmptyStateViewController()
    }

    func configureEmptyStateViewControllerBeforeDisplay(viewController: EmptyStateViewController, searchKeyword: String) {
        let boldSearchKeyword = NSAttributedString(string: searchKeyword,
                                                   attributes: [.font: EmptyStateViewController.Config.messageFont.bold])
        let format = Localization.emptySearchResults
        let message = NSMutableAttributedString(string: format)

        message.replaceFirstOccurrence(of: "%@", with: boldSearchKeyword)
        viewController.configure(.simple(message: message, image: .emptySearchResultsImage))
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
        analytics.track(.orderCreationCustomerSearch)
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
        onDidSelectSearchResult(model)
    }

    func searchResultsPredicate(keyword: String) -> NSPredicate? {
        return NSPredicate(format: "siteID == %lld AND ANY searchResults.keyword = %@", siteID, keyword)
    }
}

private extension CustomerSearchUICommand {
    enum Localization {
        static let searchBarPlaceHolder = NSLocalizedString(
            "Search all customers",
            comment: "Customer Search Placeholder")
        static let emptySearchResults = NSLocalizedString(
            "We're sorry, we couldn't find results for “%@”",
            comment: "Message for empty Customers search results. %@ is a placeholder for the text entered by the user.")
    }
}
