import UIKit
import Yosemite

class ProductListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!

    var viewModel: OrderDetailsViewModel!
    private var items = [OrderItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.items = viewModel.order.items
        title = NSLocalizedString("Details Order #\(viewModel.order.number)", comment: "Screen title: Details Order number (number)")
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        configureTableView()
    }

    func configureTableView() {
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension

        let nib = ProductDetailsTableViewCell.loadNib()
        tableView.register(nib, forCellReuseIdentifier: ProductDetailsTableViewCell.reuseIdentifier)

        let headerNib = UINib(nibName: TwoColumnSectionHeaderView.reuseIdentifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: TwoColumnSectionHeaderView.reuseIdentifier)
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> OrderItem {
        return items[indexPath.row]
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
        let itemViewModel = OrderItemViewModel(item: item, currency: viewModel.order.currency)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductDetailsTableViewCell.reuseIdentifier, for: indexPath) as? ProductDetailsTableViewCell else {
            fatalError()
        }
        cell.configure(item: itemViewModel, with: viewModel)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TwoColumnSectionHeaderView.reuseIdentifier) as? TwoColumnSectionHeaderView else {
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
    }
}

// MARK: - Private methods and more
//
private extension ProductListViewController {
    struct Constants {
        static let sectionHeight = CGFloat(44)
        static let rowHeight = CGFloat(80)
    }
}
