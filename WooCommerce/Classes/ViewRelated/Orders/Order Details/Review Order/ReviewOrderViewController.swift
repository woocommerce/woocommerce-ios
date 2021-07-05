import UIKit
import Yosemite

/// View Control for Review Order screen
/// This screen is shown when Mark Order Complete button is tapped
///
final class ReviewOrderViewController: UIViewController {

    /// View model to provide order info for review
    ///
    private let viewModel: ReviewOrderViewModel

    /// Image service needed for order item cells
    ///
    private let imageService: ImageService = ServiceLocator.imageService

    /// Table view to display order details
    ///
    @IBOutlet private var tableView: UITableView!

    init(viewModel: ReviewOrderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTableView()
    }

}

// MARK: - UI Configuration
//
private extension ReviewOrderViewController {
    func configureNavigation() {
        title = viewModel.screenTitle
    }

    func configureTableView() {
        for headerType in viewModel.allHeaderTypes {
            tableView.register(headerType.loadNib(), forHeaderFooterViewReuseIdentifier: headerType.reuseIdentifier)
        }

        for cellType in viewModel.allCellTypes {
            tableView.registerNib(for: cellType)
        }

        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
    }
}

// MARK: - UITableViewDatasource conformance
//
extension ReviewOrderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.cellType.reuseIdentifier, for: indexPath)
        setup(cell: cell, for: row, at: indexPath)
        return cell
    }
}

// MARK: - Setup cells for the table view
//
private extension ReviewOrderViewController {
    /// Setup a given UITableViewCell instance to actually display the specified Row's Payload.
    ///
    func setup(cell: UITableViewCell, for row: ReviewOrderViewModel.Row, at indexPath: IndexPath) {
        switch row {
        case .orderItem(let item):
            setupOrderItemCell(cell, with: item)
        default:
            // TODO: setup
            break
        }
    }

    /// Setup: Order item Cell
    ///
    private func setupOrderItemCell(_ cell: UITableViewCell, with item: OrderItem) {
        guard let cell = cell as? ProductDetailsTableViewCell else {
            fatalError()
        }

        let itemViewModel = viewModel.cellViewModel(for: item)
        cell.configure(item: itemViewModel, imageService: imageService)
        cell.onViewAddOnsTouchUp = { [weak self] in
            guard let self = self else { return }
            self.itemAddOnsButtonTapped(addOns: self.viewModel.filterAddons(for: item))
        }
    }
}

// MARK: - Actions
//
private extension ReviewOrderViewController {
    /// Show addon list screen
    ///
    func itemAddOnsButtonTapped(addOns: [OrderItemAttribute]) {
        let addOnsViewModel = OrderAddOnListI1ViewModel(attributes: addOns)
        let addOnsController = OrderAddOnsListViewController(viewModel: addOnsViewModel)
        let navigationController = WooNavigationController(rootViewController: addOnsController)
        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - Miscellanous
//
private extension ReviewOrderViewController {
    /// Some magic numbers for table view UI 🪄
    ///
    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }
}
