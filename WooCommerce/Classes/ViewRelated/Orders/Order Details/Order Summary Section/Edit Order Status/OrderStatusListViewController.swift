import UIKit
import Yosemite

final class OrderStatusListViewController: UIViewController {
    /// Main TableView.
    ///
    @IBOutlet private var tableView: UITableView!

    /// The status selected
    ///
    private var indexOfSelectedStatus: IndexPath? {
        didSet {
            activateApplyButton()
        }
    }

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// Order to be provided with a new status
    ///
    private let viewModel: OrderDetailsViewModelStatusSubModel

    init(viewModel: OrderDetailsViewModelStatusSubModel) {
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
        reloadTable()
    }

    private func reloadTable(completion: (() -> Void)? = nil) {
        viewModel.refreshStatuses() //X Is this necessary everytime? Seems it could be slow.
        //X TODO - needs a completion?
        tableView.reloadData()
        preselectStatusIfPossible()
        completion?()
    }

    private func preselectStatusIfPossible() {
        guard let selectedStatusIndex = viewModel.getIndexOfSelectedStatus() else {
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
        tableView.refreshControl = refreshControl

        tableView.dataSource = self
        tableView.delegate = self
    }

    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        reloadTable {
            sender.endRefreshing()
        }
    }
}

// MARK: - Navigation bar
//
extension OrderStatusListViewController {
    func configureNavigationBar() {
        configureNavigationBarStyle()
        configureTitle()
        configureLeftButton()
        configureRightButton()
    }

    func configureNavigationBarStyle() {
        navigationController?.navigationBar.barStyle = .black
    }

    func configureTitle() {
        title = NSLocalizedString("Order Status", comment: "Change order status screen - Screen title")
    }

    func configureLeftButton() {
        let dismissButtonTitle = NSLocalizedString("Cancel",
                                                   comment: "Change order status screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }

    func configureRightButton() {
        let applyButtonTitle = NSLocalizedString("Apply",
                                               comment: "Change order status screen - button title to apply selection")
        let rightBarButton = UIBarButtonItem(title: applyButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(applyButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
        deActivateApplyButton()
    }

    func activateApplyButton() {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    func deActivateApplyButton() {
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func applyButtonTapped() {
        guard let index = indexOfSelectedStatus else {
            return
        }
        viewModel.setSelectedStatus(to: index)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDatasource conformance
//
extension OrderStatusListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getNumStatusSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getNumStatuses(inSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(StatusListTableViewCell.self, for: indexPath)
        cell.textLabel?.text = viewModel.getStatusName(at: indexPath)
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
        indexOfSelectedStatus = indexPath
    }
}
