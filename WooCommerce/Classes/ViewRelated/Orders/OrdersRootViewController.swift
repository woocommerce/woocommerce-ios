import UIKit
import Yosemite
import Combine

/// The root tab controller for Orders.
///
/// This is really just a container for `OrdersTabbedViewController` with subtle fixes for the
/// XLPagerTabStrip bug in landscape. See PR#1851 (https://git.io/Jvzg8) for more information
/// about the bug.
///
/// If we eventually get XLPagerTabStrip replaced, we can merge this class with
/// `OrdersTabbedViewController`.
///
/// If you need to add additional logic, probably consider adding it to `OrdersTabbedViewController`
/// instead if possible.
///
final class OrdersRootViewController: UIViewController {

    // MARK: Child view controller

    private lazy var ordersViewController = OrdersTabbedViewController(siteID: siteID)

    // MARK: Subviews

    private lazy var containerView: UIView = {
        return UIView(frame: .zero)
    }()

    // Used to trick the navigation bar for large title (ref: issue 3 in p91TBi-45c-p2).
    private let hiddenScrollView = UIScrollView()

    private let siteID: Int64

    /// Lets us know if the store is ready to receive in person payments
    ///
    private let inPersonPaymentsUseCase = CardPresentPaymentsOnboardingUseCase()

    /// Stores any active observation.
    ///
    private var subscriptions = Set<AnyCancellable>()

    // MARK: View Lifecycle

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)

        configureTitle()
        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitle()
        configureNavigationButtons()
        configureView()
        configureContainerView()
        configureChildViewController()
        observeInPersonPaymentsStoreState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // The magical fix for XLPagerTabStrip landscape issue. h/t @jaclync https://git.io/JvzgK
        ordersViewController.view.frame = containerView.bounds
    }

    /// Presents the Details for the Notification with the specified Identifier.
    ///
    func presentDetails(for note: Note) {
        ordersViewController.presentDetails(for: note)
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }
}

// MARK: - Configuration
//
private extension OrdersRootViewController {

    func configureView() {
        view.backgroundColor = .listBackground
    }

    private func configureTitle() {
        title = NSLocalizedString("Orders", comment: "The title of the Orders tab.")
    }

    /// Set up properties for `self` as a root tab bar controller.
    ///
    func configureTabBarItem() {
        tabBarItem.title = title
        tabBarItem.image = .pagesImage
        tabBarItem.accessibilityIdentifier = "tab-bar-orders-item"
    }

    /// For `viewDidLoad` only, set up `navigationItem` buttons.
    ///
    func configureNavigationButtons() {
        let shouldShowQuickPayButton: Bool = {
            let isQuickPayEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.quickPayPrototype)
            let isInPersonPaymentsConfigured = inPersonPaymentsUseCase.state == .completed
            return isQuickPayEnabled && isInPersonPaymentsConfigured
        }()
        let buttons: [UIBarButtonItem?] = [
            ordersViewController.createSearchBarButtonItem(),
            shouldShowQuickPayButton ? ordersViewController.createAddQuickPayOrderItem() : nil
        ]
        navigationItem.rightBarButtonItems = buttons.compactMap { $0 }
    }

    func configureContainerView() {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) {
            hiddenScrollView.configureForLargeTitleWorkaround()
            // Adds the "hidden" scroll view to the root of the UIViewController for large title workaround.
            view.addSubview(hiddenScrollView)
            hiddenScrollView.translatesAutoresizingMaskIntoConstraints = false
            view.pinSubviewToAllEdges(hiddenScrollView, insets: .zero)
        }

        // A container view is pinned to all edges of the view controller.
        // to keep the consistent edge-to-edge look across app.
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(containerView)
    }

    func configureChildViewController() {
        let contentView = ordersViewController.view!
        addChild(ordersViewController)
        containerView.addSubview(contentView)
        ordersViewController.didMove(toParent: self)

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) {
            ordersViewController.scrollDelegate = self
        }
    }

    /// Observes the store `InPersonPayments` state and reconfigure navigation buttons appropriately.
    ///
    func observeInPersonPaymentsStoreState() {
        inPersonPaymentsUseCase.$state
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.configureNavigationButtons()
            }
            .store(in: &subscriptions)
        inPersonPaymentsUseCase.refresh()
    }
}

extension OrdersRootViewController: OrdersTabbedViewControllerScrollDelegate {
    func orderListScrollViewDidScroll(_ scrollView: UIScrollView) {
        hiddenScrollView.updateFromScrollViewDidScrollEventForLargeTitleWorkaround(scrollView)
    }
}
