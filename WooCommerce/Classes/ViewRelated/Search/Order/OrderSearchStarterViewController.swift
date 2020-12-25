
import Foundation
import UIKit
import struct Yosemite.OrderStatus

/// The view shown in Orders Search if there is no search keyword entered.
///
/// This shows a list of `OrderStatus` that the user can pick to filter Orders by status.
///
final class OrderSearchStarterViewController: UIViewController, KeyboardFrameAdjustmentProvider {
    private lazy var analytics = ServiceLocator.analytics

    @IBOutlet private var tableView: UITableView!

    private lazy var viewModel = OrderSearchStarterViewModel(siteID: siteID)

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
    }()

    /// Required implementation for `KeyboardFrameAdjustmentProvider`.
    var additionalKeyboardFrameHeight: CGFloat = 0

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        viewModel.activateAndForwardUpdates(to: tableView)

        // Reload because viewModel.activate executes performFetch
        tableView.reloadData()
    }

    private func configureTableView() {
        tableView.registerNib(for: TitleAndValueTableViewCell.self)

        tableView.backgroundColor = .listBackground
        tableView.delegate = self
        tableView.dataSource = self

        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

// MARK: - UITableViewDataSource

extension OrderSearchStarterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(TitleAndValueTableViewCell.self, for: indexPath)

        let cellViewModel = viewModel.cellViewModel(at: indexPath)

        cell.accessoryType = .disclosureIndicator
        cell.updateUI(title: cellViewModel.name ?? "", value: cellViewModel.total)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        NSLocalizedString("Order Status", comment: "The section title for the list of Order statuses in the Order Search.")
    }
}

// MARK: - UITableViewDelegate

extension OrderSearchStarterViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellViewModel = viewModel.cellViewModel(at: indexPath)

        analytics.trackSelectionOf(orderStatusSlug: cellViewModel.slug)

        let listViewController = makeOrderListViewController(for: cellViewModel)

        navigationController?.pushViewController(listViewController, animated: true)

        tableView.deselectSelectedRowWithAnimation(true)
    }
}

// MARK: - KeyboardScrollable

extension OrderSearchStarterViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        tableView
    }
}

// MARK: - Other Private Helpers

private extension OrderSearchStarterViewController {

    /// Make a view controller that shows the orders with the given filter.
    func makeOrderListViewController(for cellViewModel: OrderSearchStarterViewModel.CellViewModel) -> UIViewController {
        let emptyStateMessage: NSAttributedString = {
            guard let statusName = cellViewModel.name else {
                return NSAttributedString(string: NSLocalizedString("We're sorry, we couldn't find any orders.",
                                                                    comment: "Default message to show if a filtered Orders list is empty."))
            }

            let boldStatusName = NSAttributedString(string: statusName,
                                                    attributes: [.font: EmptyStateViewController.Config.messageFont.bold])

            let format = NSLocalizedString("We're sorry, we couldn't find any “%@” orders",
                                           comment: "Message shown if a filtered Orders list is empty. The %@ is a placeholder for the order status.")
            let message = NSMutableAttributedString(string: format)
            message.replaceFirstOccurrence(of: "%@", with: boldStatusName)

            return message
        }()

        let title = cellViewModel.name ?? Localization.defaultOrderListTitle
        let emptyStateConfig = EmptyStateViewController.Config.simple(message: emptyStateMessage, image: .emptySearchResultsImage)

        return OrderListViewController(
            siteID: siteID,
            title: title,
            viewModel: .init(siteID: siteID, statusFilter: cellViewModel.orderStatus),
            emptyStateConfig: emptyStateConfig
        )
    }

    enum Localization {
        static let defaultOrderListTitle = NSLocalizedString("Orders", comment: "Default title for Orders List shown when tapping on the Search filter.")
    }
}

// MARK: - Analytics

private extension Analytics {
    /// Submit events depicting selection of an `OrderStatus` in the UI.
    ///
    func trackSelectionOf(orderStatusSlug: String) {
        track(.filterOrdersOptionSelected, withProperties: ["status": orderStatusSlug])
        track(.ordersListFilterOrSearch, withProperties: ["filter": orderStatusSlug, "search": ""])
    }
}
