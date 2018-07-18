import UIKit

class ProductListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!

    var viewModel: OrderDetailsViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        title = NSLocalizedString("Details Order #\(viewModel.order.number)", comment: "Screen title: Details Order number (number)")
    }

    func configureTableView() {
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension

        let headerNib = UINib(nibName: TwoColumnSectionHeaderView.reuseIdentifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: TwoColumnSectionHeaderView.reuseIdentifier)
    }
}

extension ProductListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: TwoColumnSectionHeaderView.reuseIdentifier) as? TwoColumnSectionHeaderView else {
            fatalError()
        }
        cell.configure(leftText: viewModel.productLeftTitle, rightText: viewModel.productRightTitle)

        return cell
    }
}

extension ProductListViewController: UITableViewDelegate {

}

private extension ProductListViewController {
    struct Constants {
        static let sectionHeight = CGFloat(44)
    }
}
