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

    /// Shortcut to access Row enum of the view model
    ///
    private typealias Row = ReviewOrderViewModel.Row

    /// Shortcut to access Section enum of the view model
    ///
    private typealias Section = ReviewOrderViewModel.Section

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
    /// Configs for navigation bar
    ///
    func configureNavigation() {
        title = viewModel.screenTitle
    }

    /// Configs for table view
    ///
    func configureTableView() {
        for headerType in Section.allCases.map({ $0.headerType }) {
            tableView.register(headerType.loadNib(), forHeaderFooterViewReuseIdentifier: headerType.reuseIdentifier)
        }

        for rowType in Row.allRowTypes {
            tableView.registerNib(for: rowType)
        }

        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
    }
}

// MARK: - Sections and Rows for the order review
//
private extension ReviewOrderViewController {
    /// Some magic numbers for table view UI 🪄
    ///
    enum Constants {
        static let headerDefaultHeight = CGFloat(130)
        static let headerContainerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }
}
