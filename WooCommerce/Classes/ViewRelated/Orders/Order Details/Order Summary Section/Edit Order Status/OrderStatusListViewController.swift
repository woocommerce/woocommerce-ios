import UIKit
import Yosemite

final class OrderStatusListViewController: UIViewController {
    /// Main TableView.
    ///
    @IBOutlet private var tableView: UITableView!

    /// A view model containing all possible order statuses and the selected one.
    ///
    private let viewModel: OrderStatusListViewModel

    init(viewModel: OrderStatusListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCells()
        configureNavigationBar()
        configureTableView()
        viewModel.configureResultsController(tableView: tableView)
        tableView.reloadData()
        selectStatusIfPossible()
    }

    /// Select the row corresponding to the current order status if we can.
    ///
    private func selectStatusIfPossible() {
        guard let selectedStatusIndex = viewModel.indexOfCurrentOrderStatus() else {
            return
        }
        tableView.selectRow(at: selectedStatusIndex, animated: false, scrollPosition: .none)
    }

    /// Registers all of the available TableViewCells
    ///
    private func registerTableViewCells() {
        tableView.registerNib(for: StatusListTableViewCell.self)
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.accessibilityIdentifier = "order-status-list"
        tableView.dataSource = self
        tableView.delegate = self
    }
}

// MARK: - Navigation bar
//
extension OrderStatusListViewController {
    func configureNavigationBar() {
        configureTitle()
        configureLeftButton()
        configureRightButton()
    }

    func configureTitle() {
        title = NSLocalizedString("Order Status", comment: "Change order status screen - Screen title")
    }

    func configureLeftButton() {
        guard !viewModel.isSelectionAutoConfirmed else {
            return
        }

        let dismissButtonTitle = NSLocalizedString("Cancel",
                                                   comment: "Change order status screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }

    func configureRightButton() {
        guard !viewModel.isSelectionAutoConfirmed else {
            return
        }

        let applyButtonTitle = NSLocalizedString("Apply",
                                               comment: "Change order status screen - button title to apply selection")
        let rightBarButton = UIBarButtonItem(title: applyButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(applyButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "order-status-list-apply-button"
        enableApplyButton(viewModel.shouldEnableApplyButton)
    }

    func enableApplyButton(_ enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }

    @objc func dismissButtonTapped() {
        viewModel.didCancelSelection?()
    }

    @objc func applyButtonTapped() {
        viewModel.confirmSelectedStatus()
    }
}

// MARK: - UITableViewDatasource conformance
//
extension OrderStatusListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else {
            return 0
        }
        return viewModel.statusCount()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(StatusListTableViewCell.self, for: indexPath)
        cell.textLabel?.text = viewModel.statusName(at: indexPath)
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - UITableViewDelegate conformance
//
extension OrderStatusListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.indexOfSelectedStatus = indexPath
        enableApplyButton(viewModel.shouldEnableApplyButton)
    }
}
