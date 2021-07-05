import UIKit

/// View Control for Review Order screen
/// This screen is shown when Mark Order Complete button is tapped
///
final class ReviewOrderViewController: UIViewController {

    /// View model to provide order info for review
    ///
    private let viewModel: ReviewOrderViewModel

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
