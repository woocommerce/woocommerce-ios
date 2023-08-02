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

    var onAddCustomerDetailsManually: (() -> Void)?

    private var filter: CustomerSearchFilter = .name

    private let siteID: Int64

    private let loadResultsWhenSearchTermIsEmpty: Bool

    private let showSearchFilters: Bool

    private let stores: StoresManager

    private let analytics: Analytics

    private let featureFlagService: FeatureFlagService

    init(siteID: Int64,
         loadResultsWhenSearchTermIsEmpty: Bool = false,
         showSearchFilters: Bool = false,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         onAddCustomerDetailsManually: (() -> Void)? = nil,
         onDidSelectSearchResult: @escaping ((Customer) -> Void)) {
        self.siteID = siteID
        self.loadResultsWhenSearchTermIsEmpty = loadResultsWhenSearchTermIsEmpty
        self.showSearchFilters = showSearchFilters
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.onAddCustomerDetailsManually = onAddCustomerDetailsManually
        self.onDidSelectSearchResult = onDidSelectSearchResult
    }

    var hideCancelButton: Bool {
        featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
    }

    var hideNavigationBar: Bool {
        !featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
    }

    var syncResultsWhenSearchQueryTurnsEmpty: Bool {
        featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder) && loadResultsWhenSearchTermIsEmpty
    }

    func createHeaderView() -> UIView? {
        guard featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder),
        showSearchFilters else {
            return nil
        }
        let segmentedControl: UISegmentedControl = {
            let segmentedControl = UISegmentedControl()

            let filters: [CustomerSearchFilter] = [.name, .username, .email]
            for (index, filter) in filters.enumerated() {
                segmentedControl.insertSegment(withTitle: filter.title, at: index, animated: false)
                if filter == self.filter {
                    segmentedControl.selectedSegmentIndex = index
                }
            }
            segmentedControl.on(.valueChanged) { [weak self] sender in
                let index = sender.selectedSegmentIndex
                guard let filter = filters[safe: index] else {
                    return
                }
                self?.showResults(filter: filter)
            }
            return segmentedControl
        }()

        let containerView = UIView(frame: .zero)
        containerView.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinSubviewToAllEdges(segmentedControl, insets: .init(top: 8, left: 16, bottom: 16, right: 16))
        return containerView
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
            guard loadResultsWhenSearchTermIsEmpty else {
                return createStarterViewControllerForEmptySearch()
            }

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
    func createStarterViewControllerForEmptySearch() -> UIViewController {
        let configuration = EmptyStateViewController.Config.withButton(
            message: .init(string: ""),
            image: .customerSearchImage,
            details: Localization.emptyDefaultStateMessage,
            buttonTitle: Localization.emptyDefaultStateActionTitle
        ) { [weak self] _ in
            self?.onAddCustomerDetailsManually?()
        }

        let emptyStateViewController = EmptyStateViewController(style: .list)
        emptyStateViewController.configure(configuration)

        return emptyStateViewController
    }

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
        let searchFilter: CustomerSearchFilter

        if featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder) {
            searchFilter = showSearchFilters ? filter : .all
        } else {
            searchFilter = .name
        }

        // Before the betterCustomerSelectionInOrder feature we loaded all customers data from the search. Now we first load a light version of the customers,
        // and then all their data once when're selected. Once the feature flag is removed we will also remove the option to load light/full data
        //
        return CustomerAction.searchCustomers(siteID: siteID,
                                              keyword: keyword,
                                              retrieveFullCustomersData: !featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder),
                                              filter: searchFilter) { result in
            switch result {
            case .success:
                onCompletion?(result.isSuccess)
            case .failure(let error):
                DDLogError("Customer Search Failure \(error)")
            }
        }
    }

    func showResults(filter: CustomerSearchFilter) {
        guard filter != self.filter else {
            return
        }
        self.filter = filter
        resynchronizeModels()
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
        static let emptyDefaultStateMessage = NSLocalizedString("Search for an existing customer or",
                                                                comment: "Message to prompt users to search for customers on the customer search screen")
        static let emptyDefaultStateActionTitle = NSLocalizedString("Add details manually",
                                                                comment: "Button title for adding customer details manually on the customer search screen")
    }
}

extension CustomerSearchFilter {
    var title: String {
        switch self {
        case .all:
            return "" // Not displayed
        case .name:
            return NSLocalizedString("Name", comment: "Title of the customer search filter to search by name.")
        case .username:
            return NSLocalizedString("Username", comment: "Title of the customer search filter to search for customer that match the username.")
        case .email:
            return NSLocalizedString("Email", comment: "Title of the customer search filter to search for customers that match the email.")
        }
    }
}
