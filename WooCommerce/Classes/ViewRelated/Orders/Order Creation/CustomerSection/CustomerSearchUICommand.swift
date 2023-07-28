import Foundation
import Yosemite
import Experiments

/// Implementation of `SearchUICommand` for Customer search.
///
final class CustomerSearchUICommand: SearchUICommand {

    typealias Model = Customer
    typealias CellViewModel = TitleAndSubtitleAndStatusTableViewCell.ViewModel
    typealias ResultsControllerModel = StorageCustomer

    var searchBarPlaceholder: String {
        featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder) ?
        Localization.customerSelectorSearchBarPlaceHolder : Localization.searchBarPlaceHolder
    }

    var searchBarAccessibilityIdentifier: String = "customer-search-screen-search-field"

    var cancelButtonAccessibilityIdentifier: String = "customer-search-screen-cancel-button"

    var resynchronizeModels: (() -> Void) = {}

    var onDidSelectSearchResult: ((Customer) -> Void)

    private let siteID: Int64

    private let stores: StoresManager

    private let analytics: Analytics

    private let featureFlagService: FeatureFlagService

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         onDidSelectSearchResult: @escaping ((Customer) -> Void)) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.onDidSelectSearchResult = onDidSelectSearchResult
    }

    var hideCancelButton: Bool {
        featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
    }

    var hideNavigationBar: Bool {
        !featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
    }

    func createResultsController() -> ResultsController<StorageCustomer> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let newCustomerSelectorIsEnabled = featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
        let descriptor = newCustomerSelectorIsEnabled ?
        NSSortDescriptor(keyPath: \StorageCustomer.firstName, ascending: true) : NSSortDescriptor(keyPath: \StorageCustomer.customerID, ascending: false) 
        return ResultsController<StorageCustomer>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }

    func createStarterViewController() -> UIViewController? {
        guard !featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder) else {
            return nil
        }

        return createEmptyStateViewController()
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

        let action: CustomerAction
        if featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder),
           keyword.isEmpty {
            action = synchronizeAllLightCustomersDataAction(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        } else {
            action = searchCustomersAction(siteID: siteID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        }

        stores.dispatch(action)
    }

    func didSelectSearchResult(model: Customer, from viewController: UIViewController, reloadData: () -> Void, updateActionButton: () -> Void) {
        onDidSelectSearchResult(model)
    }

    func searchResultsPredicate(keyword: String) -> NSPredicate? {
        guard featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder),
              keyword.isEmpty else {
            return NSPredicate(format: "siteID == %lld AND ANY searchResults.keyword = %@", siteID, keyword)
        }

        return nil
    }
}

private extension CustomerSearchUICommand {
    func synchronizeAllLightCustomersDataAction(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) -> CustomerAction {
        CustomerAction.synchronizeLightCustomersData(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize) { result in
            switch result {
            case .success(_):
                onCompletion?(result.isSuccess)
            case .failure(let error):
                DDLogError("Customer Search Failure \(error)")
            }
        }
    }

    func searchCustomersAction(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) -> CustomerAction {
        CustomerAction.searchCustomers(siteID: siteID, keyword: keyword) { result in
            switch result {
            case .success(_):
                onCompletion?(result.isSuccess)
            case .failure(let error):
                DDLogError("Customer Search Failure \(error)")
            }
        }
    }
}

private extension CustomerSearchUICommand {
    enum Localization {
        static let searchBarPlaceHolder = NSLocalizedString(
            "Search all customers",
            comment: "Customer Search Placeholder")
        static let customerSelectorSearchBarPlaceHolder = NSLocalizedString(
            "Search for customers",
            comment: "Customer Search Placeholder")
        static let emptySearchResults = NSLocalizedString(
            "We're sorry, we couldn't find results for “%@”",
            comment: "Message for empty Customers search results. %@ is a placeholder for the text entered by the user.")
    }
}
