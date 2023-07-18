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

    private var subscriptions: Set<AnyCancellable> = []

    private lazy var dataSource: UITableViewDiffableDataSource<Section, CouponListViewModel.CellViewModel> = makeDataSource()
    private lazy var topBannerView: TopBannerView = createFeedbackBannerView()

    private var onDataLoaded: ((Bool) -> Void)?
    private let emptyStateAction: (() -> Void)
    private let emptyStateActionTitle: String
    private let onCouponSelected: ((Coupon) -> Void)

    init(siteID: Int64,
         showFeedbackBannerIfAppropriate: Bool,
         emptyStateActionTitle: String,
         onDataLoaded: ((Bool) -> Void)? = nil,
         emptyStateAction: @escaping (() -> Void),
         onCouponSelected: @escaping ((Coupon) -> Void)) {
        self.siteID = siteID
        self.viewModel = CouponListViewModel(siteID: siteID, showFeedbackBannerIfAppropriate: showFeedbackBannerIfAppropriate)
        self.onDataLoaded = onDataLoaded
        self.emptyStateAction = emptyStateAction
        self.emptyStateActionTitle = emptyStateActionTitle
        self.onCouponSelected = onCouponSelected
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureViewModel()
    }

    /// Triggers a refresh for the coupon list
    ///
    @objc func refreshCouponList() {
        viewModel.refreshCoupons()
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
                self?.onDataLoaded?(hasData)
            }
            .store(in: &subscriptions)

        viewModel.$couponViewModels
            .sink { [weak self] viewModels in
                guard let self = self else { return }
                var snapshot = NSDiffableDataSourceSnapshot<Section, CouponListViewModel.CellViewModel>()
                snapshot.appendSections([.main])
                snapshot.appendItems(viewModels, toSection: Section.main)

                // minimally reloads the list without computing diff or animation
                self.dataSource.applySnapshotUsingReloadData(snapshot)
            }
            .store(in: &subscriptions)

        // Call this after the state subscription for extra safety
        viewModel.viewDidLoad()
    }
}

// MARK: - Actions
private extension CouponListViewController {
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
        let viewModel = AddEditCouponViewModel(siteID: siteID,
                                               discountType: discountType,
                                               onSuccess: { [weak self] _ in
            self?.refreshCouponList()
        })
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

        onCouponSelected(coupon)
    }
}

// MARK: - View Configuration
//
private extension CouponListViewController {
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

        let configuration = EmptyStateViewController.Config.withButton(
            message: .init(string: Localization.couponCreationSuggestionMessage),
            image: .emptyCouponsImage,
            details: Localization.emptyStateDetails,
            buttonTitle: emptyStateActionTitle
        ) { [weak self] _ in
            self?.emptyStateAction()
        }

        emptyStateViewController.configure(configuration)

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

        static let feedbackBannerTitle = NSLocalizedString("View and edit coupons", comment: "Title of the feedback banner on the coupon list screen")
        static let feedbackBannerContent = NSLocalizedString(
            "We’ve been working on making it possible to view and edit coupons from your device!",
            comment: "Content of the feedback banner on the coupon list screen"
        )

        static let giveFeedbackAction = NSLocalizedString("Give feedback", comment: "Title of the feedback action button on the coupon list screen")
        static let dismissAction = NSLocalizedString("Dismiss", comment: "Title of the dismiss action button on the coupon list screen")

        static let couponCreationSuggestionMessage = NSLocalizedString(
            "Everyone loves a deal",
            comment: "The title on the placeholder overlay when there are no coupons on the coupon list screen and creating a coupon is possible.")
        static let emptyStateDetails = NSLocalizedString(
            "Boost your business by sending customers special offers and discounts.",
            comment: "The details text on the placeholder overlay when there are no coupons on the coupon list screen.")
    }
}
