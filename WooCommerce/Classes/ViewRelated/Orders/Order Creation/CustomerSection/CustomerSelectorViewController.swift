import Foundation
import SwiftUI
import WordPressUI
import UIKit
import Yosemite

/// Shows a paginated and searchable list of customers, that can be selected
///
final class CustomerSelectorViewController: UIViewController, GhostableViewController {
    private var searchViewController: SearchViewController<UnderlineableTitleAndSubtitleAndDetailTableViewCell, CustomerSearchUICommand>?
    private var emptyStateViewController: UIViewController?
    private let siteID: Int64
    private let onCustomerSelected: (Customer) -> Void
    private let viewModel: CustomerSelectorViewModel
    private let addressFormViewModel: CreateOrderAddressFormViewModel?

    let configuration: CustomerSelectorViewController.Configuration

    /// Notice presentation handler
    ///
    private var noticePresenter: NoticePresenter = DefaultNoticePresenter()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    lazy var ghostTableViewController = GhostTableViewController(options:
                                                                    GhostTableViewOptions(cellClass: UnderlineableTitleAndSubtitleAndDetailTableViewCell.self))

    /// Inits the view controller.
    /// Params:
    ///   - siteID: ID of the current site
    ///   - configuration: UI configuration for the view controller
    ///   - addressFormViewModel: Optional, has to be provided if the view has to include new customer creation.
    ///   - onCustomerSelected: Callback to be called when a customer is selected
    ///
    init(siteID: Int64,
         configuration: CustomerSelectorViewController.Configuration,
         addressFormViewModel: CreateOrderAddressFormViewModel?,
         onCustomerSelected: @escaping (Customer) -> Void) {
        viewModel = CustomerSelectorViewModel(
            siteID: siteID,
            onCustomerSelected: onCustomerSelected)

        self.siteID = siteID
        self.configuration = configuration
        self.addressFormViewModel = addressFormViewModel
        self.onCustomerSelected = onCustomerSelected

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        displayGhostContent()
        loadCustomersContent()
    }
}

extension CustomerSelectorViewController {
    struct Configuration {
        // Customer selector view's title
        let title: String

        // Whether guest-type customers can be selected or not
        var disallowSelectingGuest: Bool

        // Whether to show or hide button to create customer
        var disallowCreatingCustomer: Bool

        // Whether to show "Guest" label in the detail area of the user information for guest customers
        var showGuestLabel: Bool

        // Whether to track when a customer cell is tapped.
        var shouldTrackCustomerAdded: Bool
    }
}

private extension CustomerSelectorViewController {
    func loadCustomersContent() {
        viewModel.isEligibleForAdvancedSearch(completion: { [weak self] isEligible in
            if isEligible {
                self?.viewModel.loadCustomersListData(onCompletion: { [weak self] result in
                    guard let self = self else {
                        return
                    }

                    self.removeGhostContent()
                    switch result {
                    case .success(let thereAreResults):
                        if thereAreResults {
                            self.addSearchViewController(
                                loadResultsWhenSearchTermIsEmpty: true,
                                showSearchFilters: false,
                                showGuestLabel: configuration.showGuestLabel,
                                shouldTrackCustomerAdded: configuration.shouldTrackCustomerAdded,
                                disallowCreatingCustomer: configuration.disallowCreatingCustomer
                            )
                            self.configureActivityIndicator()
                        } else {
                            if configuration.disallowCreatingCustomer {
                                self.showEmptyState(with: self.emptyStateWithNoCreationConfiguration())

                            } else {
                                self.showEmptyState(with: self.emptyStateConfiguration())
                            }
                        }
                    case .failure:
                        self.showEmptyState(with: self.errorStateConfiguration())
                    }
                })
            } else {
                guard let self else { return }
                self.removeGhostContent()
                self.addSearchViewController(
                    loadResultsWhenSearchTermIsEmpty: false,
                    showSearchFilters: true,
                    showGuestLabel: self.configuration.showGuestLabel,
                    shouldTrackCustomerAdded: self.configuration.shouldTrackCustomerAdded,
                    disallowCreatingCustomer: self.configuration.disallowCreatingCustomer,
                    onAddCustomerDetailsManually: {
                        self.presentNewCustomerDetailsFlow()
                    })
                self.configureActivityIndicator()

            }
        })
    }

    func configureNavigation() {
        navigationItem.title = configuration.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelWasPressed))

        if !configuration.disallowCreatingCustomer {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: .plusBarButtonItemImage,
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(presentNewCustomerDetailsFlow))
            navigationItem.rightBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifier.addCustomerDetailsPlusButton
        }
    }

    func configureActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: activityIndicator.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor)
        ])
    }

    @objc func cancelWasPressed() {
        dismiss(animated: true)
    }

    @objc func presentNewCustomerDetailsFlow() {
        guard let addressFormViewModel else {
            DDLogWarn("⛔️ Unable to support new customer creation because addressFormViewModel is missing.")
            return
        }

        let editOrderAddressForm = EditOrderAddressForm(dismiss: { [weak self] action in
                                                            self?.dismiss(animated: true, completion: { [weak self] in
                                                                // Dismiss this view too
                                                                if action == .done {
                                                                    self?.dismiss(animated: true)
                                                                }
                                                            })
                                                        },
                                                        viewModel: addressFormViewModel)
        let rootViewController = UIHostingController(rootView: editOrderAddressForm)
        let navigationController = WooNavigationController(rootViewController: rootViewController)

        present(navigationController, animated: true, completion: nil)
    }

    func addSearchViewController(loadResultsWhenSearchTermIsEmpty: Bool,
                                 showSearchFilters: Bool,
                                 showGuestLabel: Bool,
                                 shouldTrackCustomerAdded: Bool,
                                 disallowCreatingCustomer: Bool,
                                 onAddCustomerDetailsManually: (() -> Void)? = nil) {
        let searchViewController = SearchViewController(
            storeID: siteID,
            command: CustomerSearchUICommand(siteID: siteID,
                                             loadResultsWhenSearchTermIsEmpty: loadResultsWhenSearchTermIsEmpty,
                                             showSearchFilters: showSearchFilters,
                                             showGuestLabel: showGuestLabel,
                                             shouldTrackCustomerAdded: shouldTrackCustomerAdded,
                                             disallowCreatingCustomer: disallowCreatingCustomer,
                                             onAddCustomerDetailsManually: onAddCustomerDetailsManually,
                                             onDidSelectSearchResult: onCustomerTapped,
                                             onDidStartSyncingAllCustomersFirstPage: {
                                                 Task { @MainActor [weak self] in
                                                     guard let searchTableView = self?.searchViewController?.tableView else {
                                                         return
                                                     }
                                                     self?.displayGhostContent(over: searchTableView)
                                                 }
                                             },
                                             onDidFinishSyncingAllCustomersFirstPage: {
                                                 Task { @MainActor [weak self] in
                                                     self?.removeGhostContent()
                                                 }
                                             }),
            cellType: UnderlineableTitleAndSubtitleAndDetailTableViewCell.self,
            cellSeparator: .none
        )

        displayViewController(searchViewController)
        self.searchViewController = searchViewController
    }

    func showEmptyState(with configuration: EmptyStateViewController.Config) {
        let emptyStateViewController = EmptyStateViewController(style: .list)
        displayViewController(emptyStateViewController)
        self.emptyStateViewController = emptyStateViewController

        emptyStateViewController.configure(configuration)
    }

    func emptyStateConfiguration() -> EmptyStateViewController.Config {
        EmptyStateViewController.Config.withButton(
            message: .init(string: Localization.emptyStateMessage),
            image: .emptySearchResultsImage,
            details: Localization.emptyStateDetails,
            buttonTitle: Localization.emptyStateActionTitle
        ) { [weak self] _ in
            self?.presentNewCustomerDetailsFlow()
        }
    }

    func emptyStateWithNoCreationConfiguration() -> EmptyStateViewController.Config {
        EmptyStateViewController.Config.simple(
            message: .init(string: Localization.emptyStateMessage),
            image: .emptySearchResultsImage
        )
    }

    func errorStateConfiguration() -> EmptyStateViewController.Config {
        EmptyStateViewController.Config.simple(message: .init(string: Localization.genericFetchCustomersError),
                                               image: .errorImage)
    }

    func displayViewController(_ viewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(viewController)
        view.addSubview(viewController.view)
        view.pinSubviewToAllEdges(viewController.view)
        viewController.didMove(toParent: self)
    }

    func onCustomerTapped(_ customer: Customer) {
        // Show alert if selecting guest is disallowed
        if configuration.disallowSelectingGuest && customer.isGuest {
            showGuestSelectionDisallowedNotice()
            return
        }

        activityIndicator.startAnimating()
        viewModel.onCustomerSelected(customer, onCompletion: { [weak self] result in
            self?.activityIndicator.stopAnimating()

            switch result {
            case .success:
                self?.dismiss(animated: true)
            case .failure:
                self?.showErrorNotice()
            }
        })
    }

    func showErrorNotice() {
        noticePresenter.presentingViewController = self
        noticePresenter.enqueue(notice: Notice(title: Localization.genericAddCustomerError, feedbackType: .error))
    }

    func showGuestSelectionDisallowedNotice() {
        noticePresenter.presentingViewController = self
        noticePresenter.enqueue(notice: Notice(title: Localization.guestSelectionDisallowedError, feedbackType: .error))
    }
}

private extension CustomerSelectorViewController {
    enum Localization {
        static let genericAddCustomerError = NSLocalizedString(
            "Failed to fetch the customer data. Please try again.",
            comment: "Error message in the Add Customer to order screen when getting the customer information")
        static let emptyStateMessage = NSLocalizedString(
            "No customers found",
            comment: "The title on the placeholder overlay when there are no customers on the customers list screen.")
        static let emptyStateDetails = NSLocalizedString(
            "Add a new customer by tapping on the button below.",
            comment: "The details text on the placeholder overlay when there are no customers on the customers list screen.")
        static let emptyStateActionTitle = NSLocalizedString(
            "Add Customer",
            comment: "The action title on the placeholder overlay when there are no customers on the customers list screen.")
        static let genericFetchCustomersError = NSLocalizedString(
            "Failed to fetch the customers data. Please try again later.",
            comment: "Error message in the Add Customer to order screen when getting the customers information")
        static let guestSelectionDisallowedError = NSLocalizedString(
            "customerSelectorViewController.guestSelectionDisallowedError",
            value: "This user is a guest, and guests can’t be used for filtering orders.",
            comment: "Error message in the Add Customer to order screen when getting the customer information")
    }

    enum AccessibilityIdentifier {
        static let addCustomerDetailsPlusButton = "add-customer-details-plus-button"
    }
}
