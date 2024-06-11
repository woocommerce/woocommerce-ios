import Foundation
import Yosemite
import Combine
import UIKit
import protocol Experiments.FeatureFlagService

/// Presents or hides the store plan info banner at the bottom of the screen.
/// Internally uses the `storePlanSynchronizer` to know when to present or hide the banner.
///
final class StorePlanBannerPresenter {
    /// View controller used to present any action needed by the free trial banner.
    ///
    private weak var viewController: UIViewController?

    /// View that will contain the banner.
    ///
    private weak var containerView: UIView?

    /// Current site ID. Needed to present the upgrades web view.
    private let siteID: Int64

    /// Closure invoked when the banner is added or removed.
    ///
    private var onLayoutUpdated: (_ bannerHeight: CGFloat) -> Void

    /// Holds a reference to the Free Trial Banner view, Needed to be able to remove it when required.
    ///
    private var storePlanBanner: UIView?

    /// Observable subscription store.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    private let stores: StoresManager
    private let storePlanSynchronizer: StorePlanSynchronizing
    private let connectivityObserver: ConnectivityObserver

    private var inAppPurchasesManager: InAppPurchasesForWPComPlansProtocol

    /// - Parameters:
    ///   - viewController: View controller used to present any action needed by the free trial banner.
    ///   - containerView: View that will contain the banner.
    ///   - onLayoutUpdated: Closure invoked when the banner is added or removed.
    init(viewController: UIViewController,
         containerView: UIView,
         siteID: Int64,
         onLayoutUpdated: @escaping (CGFloat) -> Void,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores,
         storePlanSynchronizer: StorePlanSynchronizing = ServiceLocator.storePlanSynchronizer,
         connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver,
         inAppPurchasesManager: InAppPurchasesForWPComPlansProtocol = InAppPurchasesForWPComPlansManager()) {
        self.viewController = viewController
        self.containerView = containerView
        self.siteID = siteID
        self.onLayoutUpdated = onLayoutUpdated
        self.stores = stores
        self.storePlanSynchronizer = storePlanSynchronizer
        self.connectivityObserver = connectivityObserver
        self.inAppPurchasesManager = inAppPurchasesManager
        observeStorePlan()
        observeConnectivity()
    }

    /// Reloads the site plan and the banner visibility.
    ///
    func reloadBannerVisibility() {
        storePlanSynchronizer.reloadPlan()
    }

    /// Bring banner (if visible) to the front. Useful when some content has hidden it.
    ///
    func bringBannerToFront() {
        guard let containerView, let storePlanBanner else { return }
        containerView.bringSubviewToFront(storePlanBanner)
    }
}

private extension StorePlanBannerPresenter {

    /// Observe the store plan and add or remove the banner as appropriate
    ///
    private func observeStorePlan() {
        storePlanSynchronizer.planStatePublisher.removeDuplicates()
            .combineLatest(stores.site.removeDuplicates())
            .sink { [weak self] planState, site in
                guard let self else { return }
                switch planState {
                case .loaded(let plan) where plan.isFreeTrial:
                    // Only add the banner for the free trial plan
                    let bannerViewModel = FreeTrialBannerViewModel(sitePlan: plan)
                    Task { @MainActor in
                        await self.addBanner(contentText: bannerViewModel.message)
                    }
                case .loaded(let plan) where plan.isFreePlan && site?.wasEcommerceTrial == true:
                    // Show plan expired banner for sites with expired WooExpress plans
                    Task { @MainActor in
                        await self.addBanner(contentText: Localization.expiredPlan)
                    }
                case .loading, .failed:
                    break // `.loading` and `.failed` should not change the banner visibility
                default:
                    self.removeBanner() // All other states should remove the banner
                }
            }
            .store(in: &subscriptions)
    }

    /// Hide the banner when there is no internet connection.
    /// Reload banner visibility when internet is reachable again.
    ///
    private func observeConnectivity() {
        connectivityObserver.statusPublisher.sink { [weak self] status in
            switch status {
            case .reachable:
                self?.reloadBannerVisibility()
            case .notReachable:
                self?.removeBanner()
            case .unknown:
                break // No-op
            }
        }
        .store(in: &subscriptions)
    }

    /// Adds a Free Trial bar at the bottom of the container view.
    ///
    @MainActor
    private func addBanner(contentText: String) async {
        guard let containerView else { return }

        // Remove any previous banner.
        storePlanBanner?.removeFromSuperview()

        let storePlanViewController = StorePlanBannerHostingViewController(text: contentText)
        storePlanViewController.view.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(storePlanViewController.view)
        NSLayoutConstraint.activate([
            storePlanViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            storePlanViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            storePlanViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // Let consumers know that the layout has been updated so their content is not hidden by the `freeTrialViewController`.
        DispatchQueue.main.async {
            self.onLayoutUpdated(storePlanViewController.view.frame.size.height)
        }

        // Store a reference to it to manipulate it later in `removeBanner`.
        storePlanBanner = storePlanViewController.view
    }

    /// Removes the Free Trial Banner from the container view..
    ///
    func removeBanner() {
        guard let storePlanBanner else { return }
        storePlanBanner.removeFromSuperview()
        onLayoutUpdated(.zero)
        self.storePlanBanner = nil
    }
}

private extension StorePlanBannerPresenter {
    enum Localization {
        static let expiredPlan = NSLocalizedString("Your site plan has ended.", comment: "Title on the banner when the site's WooExpress plan has expired")
    }
}
