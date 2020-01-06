import UIKit
import Yosemite


// MARK: - RefundedProductsViewController: Displays a list of all the refunded products.
//
final class RefundedProductsViewController: UIViewController {
    /// Main TableView.
    ///
    @IBOutlet private weak var tableView: UITableView!

    /// Refunds to be rendered!
    ///
    var viewModel: RefundedProductsViewModel! {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    /// Designated initalizer.
    ///
    init(viewModel: RefundedProductsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    /// NSCoder conformance.
    ///
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTableView()
    }
}


// MARK: - Setup
private extension RefundedProductsViewController {
    /// Setup: Navigation.
    ///
    func configureNavigation() {
        title = NSLocalizedString("Refunded Products",
                                  comment: "Order > Order Details > 'N Items' cell tapped > Refunded Products title")
    }

    /// Setup: TableView.
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension

        tableView.dataSource = viewModel.dataSource
    }

    /// Reloads the tableView's data, assuming the view has been loaded.
    ///
    func reloadTableViewDataIfPossible() {
        guard isViewLoaded else {
            return
        }

        tableView.reloadData()
    }

    /// Reloads the tableView's sections and data.
    ///
    func reloadTableViewSectionsAndData() {
        reloadSections()
        reloadTableViewDataIfPossible()
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        viewModel.registerTableViewCells(tableView)
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters() {
        viewModel.registerTableViewHeaderFooters(tableView)
    }
}


// MARK: - Sections
//
private extension RefundedProductsViewController {

    func reloadSections() {
        viewModel.reloadSections()
    }
}


// MARK: - Constants
//
extension RefundedProductsViewController {
    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }
}
