import UIKit
import Yosemite


class ProductListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    private var items = [OrderItem]()

    var viewModel: OrderDetailsViewModel!
    var products: [Product]? = []

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.items = viewModel.order.items
        configureMainView()
        configureTableView()
    }
}


// MARK: - Configuration
//
private extension ProductListViewController {

    /// Setup: Main View
    ///
    func configureMainView() {
        title = NSLocalizedString("Details Order #\(viewModel.order.number)", comment: "Screen title: Details Order number (number)")
        view.backgroundColor = .listBackground

        // Don't show the Order details title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension

        let nib = PickListTableViewCell.loadNib()
        tableView.register(nib, forCellReuseIdentifier: PickListTableViewCell.reuseIdentifier)

        let headerNib = UINib(nibName: TwoColumnSectionHeaderView.reuseIdentifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: TwoColumnSectionHeaderView.reuseIdentifier)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension ProductListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = itemAtIndexPath(indexPath)
        let product = lookUpProduct(by: item.productID)
        let itemViewModel = OrderItemViewModel(item: item,
                                               currency: viewModel.order.currency,
                                               product: product)
        let cellID = PickListTableViewCell.reuseIdentifier
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? PickListTableViewCell else {
            fatalError()
        }
        cell.selectionStyle = .default
        cell.configure(item: itemViewModel)

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            fatalError()
        }
        headerView.leftText = viewModel.productLeftTitle
        headerView.rightText = viewModel.productRightTitle

        return headerView
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension ProductListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let orderItem = itemAtIndexPath(indexPath)
        let productIDToLoad = orderItem.variationID == 0 ? orderItem.productID : orderItem.variationID
        productWasPressed(for: productIDToLoad)
    }
}


// MARK: - Private Helpers
//
private extension ProductListViewController {

    func itemAtIndexPath(_ indexPath: IndexPath) -> OrderItem {
        return items[indexPath.row]
    }

    func lookUpProduct(by productID: Int) -> Product? {
        return products?.filter({ $0.productID == productID }).first
    }

    /// Displays the product detail screen for the provided ProductID
    ///
    func productWasPressed(for productID: Int) {
        let loaderViewController = ProductLoaderViewController(productID: productID,
                                                               siteID: viewModel.order.siteID,
                                                               currency: viewModel.order.currency)
        let navController = WooNavigationController(rootViewController: loaderViewController)
        present(navController, animated: true, completion: nil)
    }
}


// MARK: - Constants!
//
private extension ProductListViewController {

    struct Constants {
        static let sectionHeight = CGFloat(44)
        static let rowHeight = CGFloat(80)
    }
}
