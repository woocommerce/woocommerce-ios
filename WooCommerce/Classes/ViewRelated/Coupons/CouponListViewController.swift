import Combine
import UIKit
import WordPressUI

final class CouponListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    private let viewModel: CouponListViewModel

    /// Set when an empty state view controller is displayed.
    ///
    private var emptyStateViewController: UIViewController?

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshCouponList), for: .valueChanged)
        return refreshControl
    }()

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = FooterSpinnerView()

    /// Empty Footer Placeholder. Replaces spinner view and allows footer to collapse and be completely hidden.
    ///
    private lazy var footerEmptyView = UIView(frame: .zero)

    private var subscriptions: Set<AnyCancellable> = []

    init(siteID: Int64) {
        self.viewModel = CouponListViewModel(siteID: siteID)
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        configureViewModel()
    }

    private func configureViewModel() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                self.resetViews()
                switch state {
                case .empty:
                    self.displayNoResultsOverlay()
                case .loading:
                    self.displayPlaceholderCoupons()
                case .coupons:
                    self.tableView.reloadData()
                case .refreshing:
                    self.refreshControl.beginRefreshing()
                case .loadingNextPage:
                    self.startFooterLoadingIndicator()
                case .initialized:
                    break
                }
            }
            .store(in: &subscriptions)

        // Call this after the state subscription for extra safety
        viewModel.viewDidLoad()
    }
}

// MARK: - Actions
private extension CouponListViewController {
    /// Triggers a refresh for the coupon list
    ///
    @objc func refreshCouponList() {
        viewModel.refreshCoupons()
    }

    /// Removes overlays and loading indicators if present.
    ///
    func resetViews() {
        removeNoResultsOverlay()
        removePlaceholderCoupons()
        stopFooterLoadingIndicator()
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }

    /// Starts the loading indicator in the footer, to show that another page is being fetched
    ///
    func startFooterLoadingIndicator() {
        tableView?.tableFooterView = footerSpinnerView
        footerSpinnerView.startAnimating()
    }

    /// Stops the loading indicator in the footer
    ///
    func stopFooterLoadingIndicator() {
        footerSpinnerView.stopAnimating()
        tableView?.tableFooterView = footerEmptyView
    }
}

// MARK: - TableView Delegate
//
extension CouponListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.tableWillDisplayCell(at: indexPath)
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
        tableView.addSubview(refreshControl)
        tableView.delegate = self
    }

    func registerTableViewCells() {
        TitleAndSubtitleTableViewCell.register(for: tableView)
    }
}


// MARK: - Placeholder cells
//
extension CouponListViewController {
    /// Renders the Placeholder Coupons
    ///
    func displayPlaceholderCoupons() {
        let options = GhostOptions(displaysSectionHeader: false,
                                   reuseIdentifier: TitleAndSubtitleTableViewCell.reuseIdentifier,
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
            buttonTitle: Localization.addCouponButton) { _ in }

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
        let cell = tableView.dequeueReusableCell(withIdentifier: TitleAndSubtitleTableViewCell.reuseIdentifier, for: indexPath)
        if let cellViewModel = viewModel.couponViewModels[safe: indexPath.row] {
            configure(cell as? TitleAndSubtitleTableViewCell, with: cellViewModel)
        }

        return cell
    }

    func configure(_ cell: TitleAndSubtitleTableViewCell?, with cellViewModel: CouponListCellViewModel) {
        cell?.titleLabel.text = cellViewModel.title
        cell?.subtitleLabel.text = cellViewModel.subtitle
        cell?.accessibilityLabel = cellViewModel.accessibilityLabel
        cell?.statusLabel.text = cellViewModel.status
        cell?.statusLabel.backgroundColor = cellViewModel.statusBackgroundColor
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
            "Everyone loves a deal",
            comment: "The title on the placeholder overlay when there are no coupons on the coupon list screen.")

        static let emptyStateDetails = NSLocalizedString(
            "Boost your business by sending customers special offers and discounts.",
            comment: "The description on the placeholder overlay when there are no coupons on the coupon list screen.")

        static let addCouponButton = NSLocalizedString("Add Coupon", comment: "Title for the action button to add coupon on the coupon list screen.")
    }
}
