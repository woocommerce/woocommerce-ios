import Combine
import UIKit
import WordPressUI
import Yosemite

final class CouponListViewController: UIViewController, GhostableViewController {
    @IBOutlet private weak var tableView: UITableView!
    private let viewModel: CouponListViewModel
    private let siteID: Int64

    /// Set when an empty state view controller is displayed.
    ///
    private var emptyStateViewController: UIViewController?

    lazy var ghostTableViewController = GhostTableViewController(options: GhostTableViewOptions(cellClass: TitleAndSubtitleAndStatusTableViewCell.self,
                                                                                                rowsPerSection: Constants.placeholderRowsPerSection,
                                                                                                estimatedRowHeight: Constants.estimatedRowHeight,
                                                                                                backgroundColor: .basicBackground))

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

    /// Create a `UIBarButtonItem` to be used as the create coupon button on the top-right.
    ///
    private lazy var createCouponButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(image: .plusImage,
                style: .plain,
                target: self,
                action: #selector(displayCouponTypeBottomSheet))
        button.accessibilityTraits = .button
        button.accessibilityLabel = Localization.accessibilityLabelCreateCoupons
        button.accessibilityHint = Localization.accessibilityHintCreateCoupons
        button.accessibilityIdentifier = "coupon-create-button"

        return button
    }()

    private var subscriptions: Set<AnyCancellable> = []

    private lazy var dataSource: UITableViewDiffableDataSource<Section, CouponListViewModel.CellViewModel> = makeDataSource()
    private lazy var topBannerView: TopBannerView = createFeedbackBannerView()

    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

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
                case .couponsDisabled:
                    self.displayCouponsDisabledOverlay()
                case .loading:
                    self.displayPlaceholderCoupons()
                case .coupons:
                    // the table view is reloaded when coupon view models are updated
                    // so there's no need to reload here
                    break
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

        viewModel.$couponViewModels
            .sink { [weak self] viewModels in
                guard let self = self else { return }
                var snapshot = NSDiffableDataSourceSnapshot<Section, CouponListViewModel.CellViewModel>()
                snapshot.appendSections([.main])
                snapshot.appendItems(viewModels, toSection: Section.main)

                if #available(iOS 15.0, *) {
                    // minimally reloads the list without computing diff or animation
                    self.dataSource.applySnapshotUsingReloadData(snapshot)
                } else {
                    self.dataSource.apply(snapshot)
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

    /// Triggers the coupon creation flow
    ///
    func startCouponCreation(discountType: Coupon.DiscountType) {
        let viewModel = AddEditCouponViewModel(siteID: siteID, discountType: discountType, onSuccess: {_ in })
        let addEditHostingController = AddEditCouponHostingController(viewModel: viewModel, onDisappear: { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        })
        present(addEditHostingController, animated: true)
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
        let detailsViewModel = CouponDetailsViewModel(coupon: coupon, onUpdate: { [weak self] in
            guard let self = self else { return }
            self.viewModel.refreshCoupons()
        }, onDeletion: { [weak self] in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
            let notice = Notice(title: Localization.couponDeleted, feedbackType: .success)
            self.noticePresenter.enqueue(notice: notice)
        })
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
        if hasCoupons {
            navigationItem.rightBarButtonItems = viewModel.isCreationEnabled
            ? [createCouponButtonItem, searchBarButtonItem]
            : [searchBarButtonItem]
        } else {
            navigationItem.rightBarButtonItems = viewModel.isCreationEnabled
            ? [createCouponButtonItem]
            : []
        }
    }

    func configureTableView() {
        registerTableViewCells()
        tableView.dataSource = dataSource
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.addSubview(refreshControl)
        tableView.delegate = self
    }

    func registerTableViewCells() {
        TitleAndSubtitleAndStatusTableViewCell.register(for: tableView)
    }

    func makeDataSource() -> UITableViewDiffableDataSource<Section, CouponListViewModel.CellViewModel> {
        let reuseIdentifier = TitleAndSubtitleAndStatusTableViewCell.reuseIdentifier
        return UITableViewDiffableDataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, cellViewModel in
                let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
                if let cell = cell as? TitleAndSubtitleAndStatusTableViewCell {
                    cell.configureCell(viewModel: cellViewModel)
                }
                return cell
            }
        )
    }

    /// Shows `SearchViewController`.
    ///
    @objc private func displaySearchCoupons() {
        ServiceLocator.analytics.track(.couponsListSearchTapped)
        let searchViewController = SearchViewController<TitleAndSubtitleAndStatusTableViewCell, CouponSearchUICommand>(
            storeID: siteID,
            command: CouponSearchUICommand(siteID: siteID),
            cellType: TitleAndSubtitleAndStatusTableViewCell.self,
            cellSeparator: .singleLine
        )
        let navigationController = WooNavigationController(rootViewController: searchViewController)
        present(navigationController, animated: true, completion: nil)
    }

    @objc private func displayCouponTypeBottomSheet() {
        ServiceLocator.analytics.track(.couponsListCreateTapped)
        let viewProperties = BottomSheetListSelectorViewProperties(title: Localization.createCouponAction)
        let command = DiscountTypeBottomSheetListSelectorCommand(selected: nil) { [weak self] selectedType in
            guard let self = self else { return }
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            self.startCouponCreation(discountType: selectedType)
        }

        let bottomSheet = BottomSheetListSelectorViewController(viewProperties: viewProperties, command: command, onDismiss: nil)
        let bottomSheetViewController = BottomSheetViewController(childViewController: bottomSheet)
        bottomSheetViewController.show(from: self)
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
        displayGhostContent()
    }

    /// Removes the Placeholder Coupons
    ///
    func removePlaceholderCoupons() {
        removeGhostContent()
    }
}


// MARK: - Empty state view controller
//
private extension CouponListViewController {
    /// Displays the overlay when there are no results.
    ///
    func displayNoResultsOverlay() {
        let emptyStateViewController = EmptyStateViewController(style: .list)
        displayEmptyStateViewController(emptyStateViewController)
        emptyStateViewController.configure(buildNoResultConfig())
    }

    func buildNoResultConfig() -> EmptyStateViewController.Config {
        if viewModel.isCreationEnabled {
            return .withButton(
                    message: .init(string: Localization.couponCreationSuggestionMessage),
                    image: .emptyCouponsImage,
                    details: Localization.emptyStateDetails,
                    buttonTitle: Localization.createCouponAction
            ) { [weak self] button in
                guard let self = self else { return }
                self.displayCouponTypeBottomSheet()
            }
        } else {
            return .simple(
                    message: .init(string: Localization.emptyStateMessage),
                    image: .emptyCouponsImage
            )
        }
    }

    /// Displays the overlay when coupons are disabled for the store.
    ///
    func displayCouponsDisabledOverlay() {
        let emptyStateViewController = EmptyStateViewController(style: .list)
        let config: EmptyStateViewController.Config = .withButton(message: .init(string: Localization.couponsDisabledMessage),
                                                                  image: .emptyCouponsImage,
                                                                  details: Localization.couponsDisabledDetail,
                                                                  buttonTitle: Localization.couponsDisabledAction) { [weak self] _ in
            self?.viewModel.enableCoupons()
        }
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


// MARK: - Nested Types
//
private extension CouponListViewController {
    enum Constants {
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
    }

    enum Section: Int {
        case main
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
        static let couponCreationSuggestionMessage = NSLocalizedString(
            "Everyone loves a deal",
            comment: "The title on the placeholder overlay when there are no coupons on the coupon list screen and creating a coupon is possible.")
        static let emptyStateDetails = NSLocalizedString(
            "Boost your business by sending customers special offers and discounts.",
            comment: "The details text on the placeholder overlay when there are no coupons on the coupon list screen.")

        static let couponsDisabledMessage = NSLocalizedString(
            "Everyone loves a deal",
            comment: "The title on the placeholder overlay on the coupon list screen when coupons are disabled for the store."
        )
        static let couponsDisabledDetail = NSLocalizedString(
            "You currently have Coupons disabled for this store. Enable coupons to get started.",
            comment: "The description on the placeholder overlay on the coupon list screen when coupons are disabled for the store."
        )
        static let couponsDisabledAction = NSLocalizedString(
            "Enable Coupons",
            comment: "The action button on the placeholder overlay on the coupon list screen when coupons are disabled for the store."
        )

        static let accessibilityLabelSearchCoupons = NSLocalizedString("Search coupons", comment: "Accessibility label for the Search Coupons button")
        static let accessibilityHintSearchCoupons = NSLocalizedString(
            "Retrieves a list of coupons that contain a given keyword.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to search coupons."
        )
        static let accessibilityLabelCreateCoupons = NSLocalizedString("Create coupons", comment: "Accessibility label for the Create Coupons button")
        static let accessibilityHintCreateCoupons = NSLocalizedString("Start a Coupon creation by selecting a discount type in a bottom sheet",
                comment: "VoiceOver accessibility hint, informing the user the button can be used to create coupons.")
        static let feedbackBannerTitle = NSLocalizedString("View and edit coupons", comment: "Title of the feedback banner on the coupon list screen")
        static let feedbackBannerContent = NSLocalizedString(
            "We’ve been working on making it possible to view and edit coupons from your device!",
            comment: "Content of the feedback banner on the coupon list screen"
        )
        static let createCouponAction = NSLocalizedString("Create Coupon",
                                                          comment: "Title of the create coupon button on the coupon list screen when it's empty")
        static let giveFeedbackAction = NSLocalizedString("Give Feedback", comment: "Title of the feedback action button on the coupon list screen")
        static let dismissAction = NSLocalizedString("Dismiss", comment: "Title of the dismiss action button on the coupon list screen")
        static let couponDeleted = NSLocalizedString("Coupon deleted", comment: "Notice message after deleting coupon from the Coupon Details screen")
    }
}
