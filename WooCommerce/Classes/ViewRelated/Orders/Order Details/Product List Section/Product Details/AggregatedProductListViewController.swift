import UIKit
import Yosemite


/// A simple Product List presented from the Order Details screen -> Shipping Labels Packages.
///
/// The list shows the product name and the quantity.
///
final class AggregatedProductListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!

    var viewModel: OrderDetailsViewModel!
    private var products: [Product]? = []
    var items: [AggregateOrderItem] = []

    private let imageService: ImageService = ServiceLocator.imageService

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.products = viewModel.products

        configureMainView()
        configureTableView()
    }
}


// MARK: - Configuration
//
private extension AggregatedProductListViewController {

    /// Setup: Main View
    ///
    func configureMainView() {
        title = String.pluralize(items.count, singular: Localization.titleSingular, plural: Localization.titlePlural)
        view.backgroundColor = .listBackground
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.backgroundColor = .listBackground
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.registerNib(for: PickListTableViewCell.self)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension AggregatedProductListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = itemAtIndexPath(indexPath)
        let product = lookUpProduct(by: item.productOrVariationID)
        let addOns = itemAddOnsAttributes(item: item)
        let itemViewModel = ProductDetailsCellViewModel(aggregateItem: item,
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
}


// MARK: - UITableViewDelegate Conformance
//
extension AggregatedProductListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let orderItem = itemAtIndexPath(indexPath)
        productWasPressed(orderItem: orderItem)
    }
}


// MARK: - Private Helpers
//
private extension AggregatedProductListViewController {

    func itemAtIndexPath(_ indexPath: IndexPath) -> AggregateOrderItem {
        return items[indexPath.row]
    }

    func lookUpProduct(by productID: Int64) -> Product? {
        return products?.filter({ $0.productID == productID }).first
    }

    /// Returns the item attributes that can be identified as add-ons attributes.
    /// If the "view add-ons" feature is disabled an empty array will be returned.
    ///
    func itemAddOnsAttributes(item: AggregateOrderItem) -> [OrderItemAttribute] {
        guard let product = lookUpProduct(by: item.productID), viewModel.dataSource.showAddOns else {
            return []
        }

        let globalAddOns = viewModel.dataSource.addOnGroups
        return AddOnCrossreferenceUseCase(orderItemAttributes: item.attributes, product: product, addOnGroups: globalAddOns).addOnsAttributes()
    }

    /// Displays the product details screen for the provided AggregateOrderItem
    ///
    func productWasPressed(orderItem: AggregateOrderItem) {
        let loaderViewController = ProductLoaderViewController(model: .init(aggregateOrderItem: orderItem),
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
private extension AggregatedProductListViewController {
    struct Localization {
        static let titleSingular = NSLocalizedString("%d item", comment: "For example: `1 item` in Aggregated Product List")
        static let titlePlural = NSLocalizedString("%d items",
                                       comment: "For example: `5 items` in Aggregated Product List")
    }

    struct Constants {
        static let rowHeight = CGFloat(80)
    }
}
