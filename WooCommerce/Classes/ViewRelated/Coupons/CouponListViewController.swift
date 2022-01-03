import UIKit
import WordPressUI

final class CouponListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    private var viewModel: CouponListViewModel!

    /// Set when an empty state view controller is displayed.
    ///
    private var emptyStateViewController: UIViewController?

    init(siteID: Int64) {
        super.init(nibName: type(of: self).nibName, bundle: nil)
        self.viewModel = CouponListViewModel(siteID: siteID,
                                                       didLeaveState: didLeave(state:),
                                                       didEnterState: didEnter(state:))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        viewModel.viewDidLoad()
    }

    private func didLeave(state: CouponListState) {
        switch state {
        case .empty:
            removeNoResultsOverlay()
        case .loading:
            removePlaceholderCoupons()
        default:
            break
        }
    }

    private func didEnter(state: CouponListState) {
        switch state {
        case .loading:
            displayPlaceholderCoupons()
        case .coupons:
            tableView.reloadData()
        case .empty:
            displayNoResultsOverlay()
        default:
            break
        }
    }
}


// MARK: - View Configuration
//
private extension CouponListViewController {
    func configureNavigation() {
        title = Localization.title
    }

    func configureTableView() {
        registerTableViewCells()
        tableView.dataSource = self
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
    }

    func registerTableViewCells() {
        tableView.registerNib(for: TitleBodyTableViewCell.self)
    }
}


// MARK: - Placeholder cells
//
extension CouponListViewController {
    /// Renders the Placeholder Coupons
    ///
    func displayPlaceholderCoupons() {
        let options = GhostOptions(displaysSectionHeader: false,
                                   reuseIdentifier: TitleBodyTableViewCell.reuseIdentifier,
                                   rowsPerSection: Constants.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options,
                                       style: .wooDefaultGhostStyle)
    }

    /// Removes the Placeholder Coupons
    ///
    func removePlaceholderCoupons() {
        tableView.removeGhostContent()
    }
}


// MARK: - Empty state view controller
//
extension CouponListViewController {
    /// Displays the overlay when there are no results.
    ///
    func displayNoResultsOverlay() {
        let emptyStateViewController = EmptyStateViewController(style: .list)
        let config = EmptyStateViewController.Config.withButton(
            message: .init(string: Localization.emptyStateMessage),
            image: .errorImage,
            details: Localization.emptyStateDetails,
            buttonTitle: "") { _ in }

        displayEmptyStateViewController(emptyStateViewController)
        emptyStateViewController.configure(config)
    }

    /// Shows the EmptyStateViewController as a child view controller.
    ///
    func displayEmptyStateViewController(_ emptyStateViewController: UIViewController) {
        self.emptyStateViewController = emptyStateViewController
        addChild(emptyStateViewController)

        emptyStateViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateViewController.view)
        view.pinSubviewToAllEdges(emptyStateViewController.view)

        emptyStateViewController.didMove(toParent: self)
    }

    /// Removes EmptyStateViewController child view controller if applicable.
    ///
    func removeNoResultsOverlay() {
        guard let emptyStateViewController = emptyStateViewController,
              emptyStateViewController.parent == self
        else { return }

        emptyStateViewController.willMove(toParent: nil)
        emptyStateViewController.view.removeFromSuperview()
        emptyStateViewController.removeFromParent()
        self.emptyStateViewController = nil
    }
}


// MARK: - TableView Data Source
//
extension CouponListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.couponViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TitleBodyTableViewCell.reuseIdentifier, for: indexPath)
        if let cellViewModel = viewModel.couponViewModels[safe: indexPath.row] {
            configure(cell as? TitleBodyTableViewCell, with: cellViewModel)
        }

        return cell
    }

    func configure(_ cell: TitleBodyTableViewCell?, with cellViewModel: CouponListCellViewModel) {
        cell?.titleLabel.text = cellViewModel.title
        cell?.bodyLabel.text = cellViewModel.subtitle
        cell?.accessibilityLabel = cellViewModel.accessibilityLabel
    }
}


// MARK: - Nested Types
//
private extension CouponListViewController {
    enum Constants {
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
    }
}


// MARK: - Localization
//
private extension CouponListViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "Coupons",
            comment: "Coupon management coupon list screen title")

        static let emptyStateMessage = NSLocalizedString(
            "No coupons yet",
            comment: "The text on the placeholder overlay when there are no coupons on the coupon management list")

        static let emptyStateDetails = NSLocalizedString(
            "Market your products by adding a coupon to offer your customers a discount.",
            comment: "The details on the placeholder overlay when there are no coupons on the coupon management list")
    }
}
