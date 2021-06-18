import UIKit
import Yosemite


/// A simple Product List presented from the Order Details screen -> Shipping Labels Packages.
///
/// The list shows the product name and the quantity.
///
final class AggregatedProductListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!

    private let viewModel: OrderDetailsViewModel
    private let items: [AggregateOrderItem]
    private let imageService: ImageService

    /// Init
    ///
    init(viewModel: OrderDetailsViewModel, items: [AggregateOrderItem], imageService: ImageService = ServiceLocator.imageService) {
        self.viewModel = viewModel
        self.items = items
        self.imageService = imageService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
        title = String.pluralize(items.map { $0.quantity.intValue }.reduce(0, +), singular: Localization.titleSingular, plural: Localization.titlePlural)
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
extension AggregatedProductListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = itemAtIndexPath(indexPath)
        let product = viewModel.lookUpProduct(by: item.productOrVariationID)
        let itemViewModel = ProductDetailsCellViewModel(aggregateItem: item,
                                                        currency: viewModel.order.currency,
                                                        product: product,
                                                        hasAddOns: false)
        let cell = tableView.dequeueReusableCell(PickListTableViewCell.self, for: indexPath)
        cell.selectionStyle = .default
        cell.configure(item: itemViewModel, imageService: imageService)

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
        static let sectionHeight = CGFloat(44)
        static let rowHeight = CGFloat(80)
    }
}
