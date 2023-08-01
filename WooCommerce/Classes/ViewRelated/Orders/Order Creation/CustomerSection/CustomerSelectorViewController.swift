import Foundation
import SwiftUI
import WordPressUI
import UIKit
import Yosemite

/// Shows a paginated and searchable list of customers, that can be selected
///
final class CustomerSelectorViewController: UIViewController, GhostableViewController {
    private var searchViewController: UIViewController?
    private let siteID: Int64
    private let onCustomerSelected: (Customer) -> Void
    private let viewModel: CustomerSelectorViewModel
    private let addressFormViewModel: CreateOrderAddressFormViewModel

    /// Notice presentation handler
    ///
    private var noticePresenter: NoticePresenter = DefaultNoticePresenter()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    lazy var ghostTableViewController = GhostTableViewController(options: GhostTableViewOptions(cellClass: TitleAndSubtitleAndStatusTableViewCell.self))

    init(siteID: Int64,
         addressFormViewModel: CreateOrderAddressFormViewModel,
         onCustomerSelected: @escaping (Customer) -> Void) {
        viewModel = CustomerSelectorViewModel(siteID: siteID, onCustomerSelected: onCustomerSelected)
        self.siteID = siteID
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

private extension CustomerSelectorViewController {
    func loadCustomersContent() {
        viewModel.loadCustomersListData(onCompletion: { [weak self] result in
            self?.removeGhostContent()
            self?.addSearchViewController()
            self?.configureActivityIndicator()
        })
    }

    func configureNavigation() {
        navigationItem.title = Localization.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelWasPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .plusBarButtonItemImage,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(presentNewCustomerDetailsFlow))
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
        let editOrderAddressForm = EditOrderAddressForm(dismiss: { [weak self] in
                                                            self?.dismiss(animated: true, completion: {
                                                                self?.dismiss(animated: true)
                                                            })
                                                        },
                                                        showSearchButton: false,
                                                        viewModel: addressFormViewModel)
        let rootViewController = UIHostingController(rootView: editOrderAddressForm)
        let navigationController = WooNavigationController(rootViewController: rootViewController)

        present(navigationController, animated: true, completion: nil)
    }

    func addSearchViewController() {
        let searchViewController = SearchViewController(
            storeID: siteID,
            command: CustomerSearchUICommand(siteID: siteID, onDidSelectSearchResult: onCustomerTapped),
            cellType: TitleAndSubtitleAndStatusTableViewCell.self,
            cellSeparator: .none
        )

        searchViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(searchViewController)
        view.addSubview(searchViewController.view)
        view.pinSubviewToAllEdges(searchViewController.view)
        searchViewController.didMove(toParent: self)

        self.searchViewController = searchViewController
    }

    func onCustomerTapped(_ customer: Customer) {
        activityIndicator.startAnimating()
        viewModel.onCustomerSelected(customer, onCompletion: { [weak self] result in
            self?.activityIndicator.stopAnimating()

            switch result {
            case .success(()):
                self?.dismiss(animated: true)
            case .failure(_):
                self?.showErrorNotice()
            }
        })
    }

    func showErrorNotice() {
        noticePresenter.presentingViewController = self
        noticePresenter.enqueue(notice: Notice(title: Localization.genericAddCustomerError, feedbackType: .error))
    }
}

private extension CustomerSelectorViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "Add customer details",
            comment: "Title of the order customer selection screen."
        )

        static let genericAddCustomerError = NSLocalizedString("Failed to fetch the customer data. Please try again.",
                                                                comment: "Error message in the Add Customer to order screen " +
                                                                "when getting the customer information")
    }
}
