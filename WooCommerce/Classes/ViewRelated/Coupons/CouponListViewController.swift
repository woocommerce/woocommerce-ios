import Combine
import UIKit
import WordPressUI
import class SwiftUI.UIHostingController

final class CouponListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    private let viewModel: CouponListViewModel
    private let siteID: Int64

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

    /// Create a `UIBarButtonItem` to be used as the search button on the top-left.
    ///
    private lazy var searchBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(image: .searchBarButtonItemImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(displaySearchCoupons))
        button.accessibilityTraits = .button
        button.accessibilityLabel = Localization.accessibilityLabelSearchCoupons
        button.accessibilityHint = Localization.accessibilityHintSearchCoupons
        button.accessibilityIdentifier = "coupon-search-button"

        return button
    }()

    private var subscriptions: Set<AnyCancellable> = []

    private lazy var topBannerView: TopBannerView = createFeedbackBannerView()

    init(siteID: Int64) {
        self.siteID = siteID
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

        viewModel.$shouldDisplayFeedbackBanner
            .removeDuplicates()
            .sink { [weak self] isVisible in
                guard let self = self else { return }
                if isVisible {
                    // Configure header container view
                    let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(self.tableView.frame.width), height: 0))
                    headerContainer.addSubview(self.topBannerView)
                    headerContainer.pinSubviewToSafeArea(self.topBannerView)

                    self.tableView.tableHeaderView = headerContainer
                    self.tableView.updateHeaderHeight()
                } else {
                    self.topBannerView.removeFromSuperview()
                    self.tableView.tableHeaderView = nil
                }
            }
            .store(in: &subscriptions)

        viewModel.$couponViewModels
            .map { viewModels -> Bool in
                viewModels.isNotEmpty
            }
            .removeDuplicates()
            .sink { [weak self] hasData in
                self?.configureNavigationBarItems(hasCoupons: hasData)
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let coupon = viewModel.coupon(at: indexPath) else {
            return
        }
        let detailsViewModel = CouponDetailsViewModel(coupon: coupon)
        let hostingController = CouponDetailsHostingController(viewModel: detailsViewModel)
        navigationController?.pushViewController(hostingController, animated: true)
    }
}


// MARK: - View Configuration
//
private extension CouponListViewController {
    func configureNavigation() {
        title = Localization.title
    }

    func configureNavigationBarItems(hasCoupons: Bool) {
        navigationItem.rightBarButtonItems = hasCoupons ? [searchBarButtonItem] : []
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
        TitleAndSubtitleAndStatusTableViewCell.register(for: tableView)
    }

    /// Shows `SearchViewController`.
    ///
    @objc private func displaySearchCoupons() {
        ServiceLocator.analytics.track(.couponsListSearchTapped)
        let searchViewController = SearchViewController<TitleAndSubtitleAndStatusTableViewCell, CouponSearchUICommand>(
            storeID: siteID,
            command: CouponSearchUICommand(),
            cellType: TitleAndSubtitleAndStatusTableViewCell.self,
            cellSeparator: .singleLine
        )
        let navigationController = WooNavigationController(rootViewController: searchViewController)
        present(navigationController, animated: true, completion: nil)
    }

    func createFeedbackBannerView() -> TopBannerView {
        let giveFeedbackAction = TopBannerViewModel.ActionButton(title: Localization.giveFeedbackAction) { [weak self] _ in
            ServiceLocator.analytics.track(event: .featureFeedbackBanner(context: .couponManagement, action: .gaveFeedback))
            self?.presentCouponsFeedback()
        }
        let dismissAction = TopBannerViewModel.ActionButton(title: Localization.dismissAction) { [weak self] _ in
            ServiceLocator.analytics.track(event: .featureFeedbackBanner(context: .couponManagement, action: .dismissed))
            self?.viewModel.dismissFeedbackBanner()
        }
        let expandedStateChangeHandler: (() -> Void)? = { [weak self] in
            self?.tableView.updateHeaderHeight()
        }
        let actions = [giveFeedbackAction, dismissAction]
        let viewModel = TopBannerViewModel(title: Localization.feedbackBannerTitle,
                                           infoText: Localization.feedbackBannerContent,
                                           icon: .speakerIcon.withRenderingMode(.alwaysTemplate),
                                           iconTintColor: .wooCommercePurple(.shade50),
                                           isExpanded: false,
                                           topButton: .chevron(handler: expandedStateChangeHandler),
                                           actionButtons: actions)
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false
        return topBannerView
    }

    /// Presents coupons survey
    ///
    func presentCouponsFeedback() {
        // Present survey
        let navigationController = SurveyCoordinatingController(survey: .couponManagement)
        present(navigationController, animated: true, completion: nil)
    }
}


// MARK: - Placeholder cells
//
extension CouponListViewController {
    /// Renders the Placeholder Coupons
    ///
    func displayPlaceholderCoupons() {
        let options = GhostOptions(displaysSectionHeader: false,
                                   reuseIdentifier: TitleAndSubtitleAndStatusTableViewCell.reuseIdentifier,
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
        let config = EmptyStateViewController.Config.simple(
            message: .init(string: Localization.emptyStateMessage),
            image: .emptyCouponsImage
        )

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
        let cell = tableView.dequeueReusableCell(withIdentifier: TitleAndSubtitleAndStatusTableViewCell.reuseIdentifier, for: indexPath)
        if let cellViewModel = viewModel.couponViewModels[safe: indexPath.row],
            let cell = cell as? TitleAndSubtitleAndStatusTableViewCell {
            cell.configureCell(viewModel: cellViewModel)
        }

        return cell
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
            "No coupons found",
            comment: "The title on the placeholder overlay when there are no coupons on the coupon list screen.")

        static let accessibilityLabelSearchCoupons = NSLocalizedString("Search coupons", comment: "Accessibility label for the Search Coupons button")
        static let accessibilityHintSearchCoupons = NSLocalizedString(
            "Retrieves a list of coupons that contain a given keyword.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to search coupons."
        )
        static let feedbackBannerTitle = NSLocalizedString("View and edit coupons", comment: "Title of the feedback banner on the coupon list screen")
        static let feedbackBannerContent = NSLocalizedString(
            "We’ve been working on making it possible to view and edit coupons from your device!",
            comment: "Content of the feedback banner on the coupon list screen"
        )
        static let giveFeedbackAction = NSLocalizedString("Give Feedback", comment: "Title of the feedback action button on the coupon list screen")
        static let dismissAction = NSLocalizedString("Dismiss", comment: "Title of the dismiss action button on the coupon list screen")
    }
}
