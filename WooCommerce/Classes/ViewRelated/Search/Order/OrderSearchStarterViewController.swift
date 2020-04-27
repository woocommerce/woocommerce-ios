
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

    private lazy var viewModel = OrderSearchStarterViewModel()

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
    }()

    /// Required implementation for `KeyboardFrameAdjustmentProvider`.
    var additionalKeyboardFrameHeight: CGFloat = 0

    init() {
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        viewModel.activate(using: tableView)
    }

    private func configureTableView() {
        tableView.backgroundColor = .listBackground
        tableView.delegate = self

        tableView.register(BasicTableViewCell.loadNib(),
                           forCellReuseIdentifier: BasicTableViewCell.reuseIdentifier)

        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

// MARK: - UITableViewDelegate

extension OrderSearchStarterViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let orderStatus = viewModel.orderStatus(at: indexPath)

        analytics.trackSelectionOf(orderStatus: orderStatus)

        let ordersViewController = OrdersViewController(
            title: orderStatus.name ?? NSLocalizedString("Orders", comment: "Default title for Orders List shown when tapping on the Search filter."),
            statusFilter: orderStatus
        )

        navigationController?.pushViewController(ordersViewController, animated: true)

        tableView.deselectSelectedRowWithAnimation(true)
    }
}

// MARK: - KeyboardScrollable

extension OrderSearchStarterViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        tableView
    }
}

// MARK: - Analytics

private extension Analytics {
    /// Submit events depicting selection of an `OrderStatus` in the UI.
    ///
    func trackSelectionOf(orderStatus: OrderStatus) {
        track(.filterOrdersOptionSelected, withProperties: ["status": orderStatus.slug])
        track(.ordersListFilterOrSearch, withProperties: ["filter": orderStatus.slug, "search": ""])
    }
}
