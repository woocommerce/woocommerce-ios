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

        for rowType in Row.allCases.map({ $0.rowType }) {
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
    /// Section types for Review Order screen
    ///
    enum Section: CaseIterable {
        case products
        case customerInformation
        case tracking

        var headerType: UITableViewHeaderFooterView.Type {
            switch self {
            case .products:
                return PrimarySectionHeaderView.self
            case .customerInformation, .tracking:
                return TwoColumnSectionHeaderView.self
            }
        }
    }

    /// Row types for Review Order screen
    ///
    enum Row: CaseIterable {
        case orderItem
        case customerNote
        case shippingAddress
        case shippingMethod
        case billingDetail
        case tracking
        case trackingAdd

        var rowType: UITableViewCell.Type {
            switch self {
            case .orderItem:
                return ProductDetailsTableViewCell.self
            case .customerNote:
                return CustomerNoteTableViewCell.self
            case .shippingAddress:
                return CustomerInfoTableViewCell.self
            case .shippingMethod:
                return CustomerNoteTableViewCell.self
            case .billingDetail:
                return WooBasicTableViewCell.self
            case .tracking:
                return OrderTrackingTableViewCell.self
            case .trackingAdd:
                return LeftImageTableViewCell.self
            }
        }
    }

    /// Some magic numbers for table view UI 🪄
    ///
    enum Constants {
        static let headerDefaultHeight = CGFloat(130)
        static let headerContainerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }
}
