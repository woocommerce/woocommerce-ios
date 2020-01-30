
import Foundation
import UIKit

/// The view shown in Orders Search if there is no search keyword entered.
///
final class OrderSearchStarterViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!

    private lazy var viewModel = OrderSearchStarterViewModel()

    init() {
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
    }

    private func configureTableView() {
        tableView.backgroundColor = .listBackground

        viewModel.configureDataSource(for: tableView)
    }
}
