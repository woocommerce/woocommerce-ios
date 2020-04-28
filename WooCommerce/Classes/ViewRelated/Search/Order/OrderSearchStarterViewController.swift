
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

        viewModel.activateAndForwardUpdates(to: tableView)
    }

    private func configureTableView() {
        tableView.register(SettingTitleAndValueTableViewCell.loadNib(),
                           forCellReuseIdentifier: SettingTitleAndValueTableViewCell.reuseIdentifier)

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
        guard let cell =
            tableView.dequeueReusableCell(withIdentifier: SettingTitleAndValueTableViewCell.reuseIdentifier,
                                          for: indexPath) as? SettingTitleAndValueTableViewCell else {
                                            fatalError("Unexpected or missing cell")
        }

        let orderStatus = viewModel.orderStatus(at: indexPath)

        cell.accessoryType = .disclosureIndicator
        cell.updateUI(title: orderStatus.name ?? "", value: "\(orderStatus.total)")

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        NSLocalizedString("Order Status", comment: "The section title for the list of Order statuses in the Order Search.")
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
