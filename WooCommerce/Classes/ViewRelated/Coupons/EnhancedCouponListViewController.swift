import Foundation
import WordPressUI
import UIKit
import Yosemite

/// Shows a coupons list plus the entry to other accessory actions: search, creation.
///
final class EnhancedCouponListViewController: UIViewController {
    private var couponListViewController: CouponListViewController?
    private let siteID: Int64

    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    init(siteID: Int64) {
        self.siteID = siteID

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureCouponListViewController()
    }

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
}

private extension EnhancedCouponListViewController {
    func configureCouponListViewController() {
        let couponListViewController = CouponListViewController(siteID: siteID,
                                                            showFeedbackBannerIfAppropriate: true,
                                                            emptyStateActionTitle: Localization.createCouponAction,
                                                            onDataLoaded: configureNavigationBarItems,
                                                            emptyStateAction: displayCouponTypeBottomSheet,
                                                            onCouponSelected: showDetails)

        couponListViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(couponListViewController)
        view.addSubview(couponListViewController.view)
        view.pinSubviewToAllEdges(couponListViewController.view)
        couponListViewController.didMove(toParent: self)

        self.couponListViewController = couponListViewController
    }

    func configureNavigation() {
        title = Localization.title
    }

    func configureNavigationBarItems(hasCoupons: Bool) {
        if hasCoupons {
            navigationItem.rightBarButtonItems = [createCouponButtonItem, searchBarButtonItem]
        } else {
            navigationItem.rightBarButtonItems = [createCouponButtonItem]
        }
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

    /// Triggers the coupon creation flow
    ///
    func startCouponCreation(discountType: Coupon.DiscountType) {
        let viewModel = AddEditCouponViewModel(siteID: siteID,
                                               discountType: discountType,
                                               onSuccess: { [weak self] _ in
            self?.couponListViewController?.refreshCouponList()
        })
        let addEditHostingController = AddEditCouponHostingController(viewModel: viewModel, onDisappear: { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        })
        present(addEditHostingController, animated: true)
    }

    @objc private func displayCouponTypeBottomSheet() {
        ServiceLocator.analytics.track(.couponsListCreateTapped)
        let viewProperties = BottomSheetListSelectorViewProperties(subtitle: Localization.createCouponAction)
        let command = DiscountTypeBottomSheetListSelectorCommand(selected: nil) { [weak self] selectedType in
            guard let self = self else { return }
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            self.startCouponCreation(discountType: selectedType)
        }

        let bottomSheet = BottomSheetListSelectorViewController(viewProperties: viewProperties, command: command, onDismiss: nil)
        let bottomSheetViewController = BottomSheetViewController(childViewController: bottomSheet)
        bottomSheetViewController.show(from: self)
    }

    func showDetails(from coupon: Coupon) {
        let detailsViewModel = CouponDetailsViewModel(coupon: coupon, onUpdate: { [weak self] in
            guard let self = self else { return }
            self.couponListViewController?.refreshCouponList()
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

// MARK: - Localization
//
extension EnhancedCouponListViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "Coupons",
            comment: "Coupon management coupon list screen title")
        static let accessibilityLabelCreateCoupons = NSLocalizedString("Create coupons", comment: "Accessibility label for the Create Coupons button")
        static let accessibilityHintCreateCoupons = NSLocalizedString("Start a Coupon creation by selecting a discount type in a bottom sheet",
                comment: "VoiceOver accessibility hint, informing the user the button can be used to create coupons.")
        static let accessibilityLabelSearchCoupons = NSLocalizedString("Search coupons", comment: "Accessibility label for the Search Coupons button")
        static let accessibilityHintSearchCoupons = NSLocalizedString(
            "Retrieves a list of coupons that contain a given keyword.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to search coupons."
        )
        static let couponDeleted = NSLocalizedString("Coupon deleted", comment: "Notice message after deleting coupon from the Coupon Details screen")
        static let createCouponAction = NSLocalizedString("Create Coupon",
                                                          comment: "Title of the create coupon button on the coupon list screen when it's empty")
    }
}
