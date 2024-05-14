import Foundation
import Yosemite
import Experiments
import protocol WooFoundation.Analytics

/// Implementation of `SearchUICommand` for Customer search.
///
final class CustomerSearchUICommand: SearchUICommand {

    typealias Model = Customer
    typealias CellViewModel = UnderlineableTitleAndSubtitleAndDetailTableViewCell.ViewModel
    typealias ResultsControllerModel = StorageCustomer

    var searchBarPlaceholder: String {
        guard featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder) else {
            return Localization.searchBarPlaceHolder
        }

        return showSearchFilters ? Localization.customerFiltersSearchBarPlaceHolder : Localization.customerSelectorSearchBarPlaceHolder
    }

    let returnKeyType = UIReturnKeyType.done

    var searchBarAccessibilityIdentifier: String = "customer-search-screen-search-field"

    var cancelButtonAccessibilityIdentifier: String = "customer-search-screen-cancel-button"

    var resynchronizeModels: (() -> Void) = {}

    var onDidSelectSearchResult: ((Customer) -> Void)

    var onDidStartSyncingAllCustomersFirstPage: (() -> Void)?

    var onDidFinishSyncingAllCustomersFirstPage: (() -> Void)?

    var onAddCustomerDetailsManually: (() -> Void)?

    private var filter: CustomerSearchFilter = .name

    private let siteID: Int64

    private let loadResultsWhenSearchTermIsEmpty: Bool

    private let showSearchFilters: Bool

    private let stores: StoresManager

    private let analytics: Analytics

    private let featureFlagService: FeatureFlagService

    private var searchTerm: String?

    // If customer is a guest, show "Guest" in the detail section
    private let showGuestLabel: Bool

    // Whether to track customer addition
    private let shouldTrackCustomerAdded: Bool

    // Whether to hide button for creating customer in empty state
    private let disallowCreatingCustomer: Bool

    init(siteID: Int64,
         loadResultsWhenSearchTermIsEmpty: Bool = false,
         showSearchFilters: Bool = false,
         showGuestLabel: Bool = false,
         shouldTrackCustomerAdded: Bool = true,
         disallowCreatingCustomer: Bool = false,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         onAddCustomerDetailsManually: (() -> Void)? = nil,
         onDidSelectSearchResult: @escaping ((Customer) -> Void),
         onDidStartSyncingAllCustomersFirstPage: (() -> Void)? = nil,
         onDidFinishSyncingAllCustomersFirstPage: (() -> Void)? = nil) {
        self.siteID = siteID
        self.loadResultsWhenSearchTermIsEmpty = loadResultsWhenSearchTermIsEmpty
        self.showSearchFilters = showSearchFilters
        self.showGuestLabel = showGuestLabel
        self.shouldTrackCustomerAdded = shouldTrackCustomerAdded
        self.disallowCreatingCustomer = disallowCreatingCustomer
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.onAddCustomerDetailsManually = onAddCustomerDetailsManually
        self.onDidSelectSearchResult = onDidSelectSearchResult
        self.onDidStartSyncingAllCustomersFirstPage = onDidStartSyncingAllCustomersFirstPage
        self.onDidFinishSyncingAllCustomersFirstPage = onDidFinishSyncingAllCustomersFirstPage
    }

    var hideCancelButton: Bool {
        featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
    }

    var hideNavigationBar: Bool {
        !featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
    }

    var makeSearchBarFirstResponderOnStart: Bool {
        !featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
    }

    var syncResultsWhenSearchQueryTurnsEmpty: Bool {
        featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder) && loadResultsWhenSearchTermIsEmpty
    }

    let adjustTableViewBottomInsetWhenKeyboardIsShown = false

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
                return createStarterViewControllerForEmptySearch(disallowCreatingCustomer: disallowCreatingCustomer)
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

    func createCellViewModel(model: Customer) -> UnderlineableTitleAndSubtitleAndDetailTableViewCell.ViewModel {
        let detail = showGuestLabel && model.customerID == 0 ? Localization.guestLabel : model.username ?? ""

        return CellViewModel(
            id: "\(model.customerID)",
            title: "\(model.firstName ?? "") \(model.lastName ?? "")",
            placeholderTitle: Localization.titleCellPlaceholder,
            placeholderSubtitle: Localization.subtitleCellPlaceholder,
            subtitle: model.email,
            accessibilityLabel: "",
            detail: detail,
            underlinedText: searchTerm?.count ?? 0 > 1 ? searchTerm : "" // Only underline the search term if it's longer than 1 character
        )
    }

    func synchronizeModels(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        searchTerm = keyword
        analytics.track(.orderCreationCustomerSearch)

        let action: CustomerAction
        if featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder),
           keyword.isEmpty {
            if syncResultsWhenSearchQueryTurnsEmpty {
                if pageNumber == 1 {
                    onDidStartSyncingAllCustomersFirstPage?()
                }

                action = synchronizeAllLightCustomersDataAction(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
            } else {
                // As we don't have to show anything if the search query is empty, let's reset the customers database
                action = .deleteAllCustomers(siteID: siteID, onCompletion: { onCompletion?(true) })
            }
        } else {
            action = searchCustomersAction(siteID: siteID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        }

        stores.dispatch(action)
    }

    func didSelectSearchResult(model: Customer, from viewController: UIViewController, reloadData: () -> Void, updateActionButton: () -> Void) {
        if shouldTrackCustomerAdded {
            analytics.track(.orderCreationCustomerAdded)
        }
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
    func createStarterViewControllerForEmptySearch(disallowCreatingCustomer: Bool) -> UIViewController {
        let configuration: EmptyStateViewController.Config

        if disallowCreatingCustomer {
            configuration = .simple(
                message: .init(string: Localization.emptyDefaultStateNoCreationMessage),
                image: .customerSearchImage
            )
        } else {
            configuration = .withButton(
                message: .init(string: ""),
                image: .customerSearchImage,
                details: Localization.emptyDefaultStateMessage,
                buttonTitle: Localization.emptyDefaultStateActionTitle
            ) { [weak self] _ in
                self?.analytics.track(.orderCreationCustomerAddManuallyTapped)
                self?.onAddCustomerDetailsManually?()
            }
        }

        let emptyStateViewController = EmptyStateViewController(style: .list)
        emptyStateViewController.configure(configuration)

        return emptyStateViewController
    }

    func synchronizeAllLightCustomersDataAction(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) -> CustomerAction {
        CustomerAction.synchronizeLightCustomersData(siteID: siteID,
                                                     pageNumber: pageNumber,
                                                     pageSize: pageSize,
                                                     orderby: .name,
                                                     order: .asc,
                                                     filterEmpty: .email) { [weak self] result in
            switch result {
            case .success:
                onCompletion?(result.isSuccess)
            case .failure(let error):
                DDLogError("Customer Search Failure \(error)")
            }

            if pageNumber == 1 {
                self?.onDidFinishSyncingAllCustomersFirstPage?()
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

        // Before the betterCustomerSelectionInOrder feature we loaded all customers fields from the search. Now we first load a light version of the customers,
        // and then all their data once when're selected. We will remove the option to choose light/full data together with the betterCustomerSelectionInOrder
        // and retrieve only light data when searching.
        //
        return CustomerAction.searchCustomers(siteID: siteID,
                                              pageNumber: pageNumber,
                                              pageSize: pageSize,
                                              orderby: .name,
                                              order: .asc,
                                              keyword: keyword,
                                              retrieveFullCustomersData: !featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder),
                                              filter: searchFilter,
                                              filterEmpty: .email) { result in
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
        static let customerFiltersSearchBarPlaceHolder = NSLocalizedString(
            "Search for customers by",
            comment: "Customer Search Placeholder when showing filters")
        static let emptySearchResults = NSLocalizedString(
            "We're sorry, we couldn't find results for “%@”",
            comment: "Message for empty Customers search results. %@ is a placeholder for the text entered by the user.")
        static let titleCellPlaceholder = NSLocalizedString("No name", comment: "Placeholder when there's no customer name in the list")
        static let subtitleCellPlaceholder = NSLocalizedString("No email address", comment: "Placeholder when there's no customer email in the list")
        static let emptyDefaultStateMessage = NSLocalizedString("Search for an existing customer or",
                                                                comment: "Message to prompt users to search for customers on the customer search screen")
        static let emptyDefaultStateActionTitle = NSLocalizedString("Add details manually",
                                                                comment: "Button title for adding customer details manually on the customer search screen")
        static let emptyDefaultStateNoCreationMessage = NSLocalizedString(
            "customerSearchUICommand.emptyDefaultStateNoCreationMessage",
            value: "Search for an existing customer",
            comment: "Message to prompt users to search for customers on the customer search screen")

        static let guestLabel = NSLocalizedString(
            "customerSearchUICommand.guestLabel",
            value: "Guest",
            comment: "The label that can be shown optionally for guest customers")
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
