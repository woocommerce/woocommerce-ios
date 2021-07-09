import UIKit
import Yosemite


/// A simple Product List presented from the Order Details screen.
///
/// The list shows the product name and the purchased quantity.
///
final class ProductListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    private var items = [OrderItem]()

    var viewModel: OrderDetailsViewModel!
    var products: [Product]? = []

    private let imageService: ImageService = ServiceLocator.imageService

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.items = viewModel.order.items
        self.products = viewModel.products
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
        let titleFormat = NSLocalizedString("Details Order #%1$@", comment: "Screen title: Details Order number. Parameters: %1$@ - order number")
        title = String.localizedStringWithFormat(titleFormat, viewModel.order.number)
        view.backgroundColor = .listBackground
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.registerNib(for: PickListTableViewCell.self)

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
        let product = lookUpProduct(by: item.productOrVariationID)
        let addOns = itemAddOnsAttributes(item: item)
        let itemViewModel = ProductDetailsCellViewModel(item: item,
                                                        currency: viewModel.order.currency,
                                                        product: product,
                                                        hasAddOns: addOns.isNotEmpty)
        let cell = tableView.dequeueReusableCell(PickListTableViewCell.self, for: indexPath)
        cell.selectionStyle = .default
        cell.configure(item: itemViewModel, imageService: imageService)
        cell.onViewAddOnsTouchUp = { [weak self] in
            self?.itemAddOnsButtonTapped(addOns: addOns)
        }

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
        productWasPressed(orderItem: orderItem)
    }
}


// MARK: - Private Helpers
//
private extension ProductListViewController {

    func itemAtIndexPath(_ indexPath: IndexPath) -> OrderItem {
        return items[indexPath.row]
    }

    func lookUpProduct(by productID: Int64) -> Product? {
        return products?.filter({ $0.productID == productID }).first
    }

    /// Returns the item attributes that can be identified as add-ons attributes.
    /// If the "view add-ons" feature is disabled an empty array will be returned.
    ///
    func itemAddOnsAttributes(item: OrderItem) -> [OrderItemAttribute] {
        guard let product = lookUpProduct(by: item.productID), viewModel.dataSource.showAddOns else {
            return []
        }

        let globalAddOns = viewModel.dataSource.addOnGroups
        return AddOnCrossreferenceUseCase(orderItemAttributes: item.attributes, product: product, addOnGroups: globalAddOns).addOnsAttributes()
    }

    /// Displays the product details screen for the provided OrderItem
    ///
    func productWasPressed(orderItem: OrderItem) {
        let loaderViewController = ProductLoaderViewController(model: .init(orderItem: orderItem),
                                                               siteID: viewModel.order.siteID,
                                                               forceReadOnly: true)
        let navController = WooNavigationController(rootViewController: loaderViewController)
        present(navController, animated: true, completion: nil)
    }

    private func itemAddOnsButtonTapped(addOns: [OrderItemAttribute]) {
        let addOnsViewModel = OrderAddOnListI1ViewModel(attributes: addOns)
        let addOnsController = OrderAddOnsListViewController(viewModel: addOnsViewModel)
        let navigationController = WooNavigationController(rootViewController: addOnsController)
        present(navigationController, animated: true, completion: nil)
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
