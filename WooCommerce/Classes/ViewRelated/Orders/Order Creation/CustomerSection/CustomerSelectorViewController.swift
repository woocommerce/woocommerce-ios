import Foundation
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

    lazy var ghostTableViewController = GhostTableViewController(options: GhostTableViewOptions(cellClass: TitleAndSubtitleAndStatusTableViewCell.self))

    init(siteID: Int64,
         onCustomerSelected: @escaping (Customer) -> Void) {

        viewModel = CustomerSelectorViewModel(siteID: siteID, onCustomerSelected: onCustomerSelected)
        self.siteID = siteID
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
        ServiceLocator.stores.dispatch(CustomerAction.synchronizeLightCustomersData(siteID: siteID,
                                                                                    pageNumber: Constants.firstPageNumber,
                                                                                    pageSize: Constants.pageSize, onCompletion: { [weak self] result in
            self?.removeGhostContent()
            self?.addSearchViewController()
        }))
    }

    func configureNavigation() {
        navigationItem.title = Localization.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelWasPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .plusBarButtonItemImage,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(presentNewCustomerDetailsFlow))
    }

    @objc func cancelWasPressed() {
        dismiss(animated: true)
    }

    @objc func presentNewCustomerDetailsFlow() {}

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
        viewModel.onCustomerSelected(customer, onCompletion: { [weak self] in
            self?.dismiss(animated: true)
        })
    }
}

private extension CustomerSelectorViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "Add customer details",
            comment: "Title of the order customer selection screen."
        )
    }

    enum Constants {
        static let pageSize = 25
        static let firstPageNumber = 1
    }
}
