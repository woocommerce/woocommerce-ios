import UIKit

/// The entry UI for adding/editing a Product.
final class ProductFormViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let dataSource: ProductFormDataSource

    init() {
        dataSource = DefaultProductFormDataSource()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
    }
}

private extension ProductFormViewController {
    func configureTableView() {
        tableView.dataSource = dataSource

        tableView.reloadData()
    }
}
