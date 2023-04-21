import Foundation
import Combine
import UIKit

/// Presents or hides the free trial banner at the bottom of the screen.
/// Internally uses the `storePlanSynchronizer` to know when to present or hide the banner.
///
final class FreeTrialBannerPresenter {
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
    private var onLayoutUpdated: (_ containerView: UIView, _ bannerHeight: CGFloat) -> Void

    /// Holds a reference to the Free Trial Banner view, Needed to be able to remove it when required.
    ///
    private var freeTrialBanner: UIView?

    /// Observable subscription store.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    /// - Parameters:
    ///   - viewController: View controller used to present any action needed by the free trial banner.
    ///   - containerView: View that will contain the banner.
    ///   - onLayoutUpdated: Closure invoked when the banner is added or removed.
    init(viewController: UIViewController, containerView: UIView, siteID: Int64, onLayoutUpdated: @escaping (UIView, CGFloat) -> Void) {
        self.viewController = viewController
        self.containerView = containerView
        self.siteID = siteID
        self.onLayoutUpdated = onLayoutUpdated
        observeStorePlan() // TODO: hide banner when no internet connection
    }

    /// Reloads the site plan and the banner visibility.
    ///
    func reloadBannerVisibility() {
        ServiceLocator.storePlanSynchronizer.reloadPlan()
    }
}

private extension FreeTrialBannerPresenter {

    /// Observe the store plan and add or remove the banner as appropriate
    ///
    private func observeStorePlan() {
        ServiceLocator.storePlanSynchronizer.$planState.sink { [weak self] planState in
            guard let self else { return }
            switch planState {
            case .loaded(let plan) where plan.isFreeTrial:
                // Only add the banner for the free trial plan
                let bannerViewModel = FreeTrialBannerViewModel(sitePlan: plan)
                self.addBanner(contentText: bannerViewModel.message)
            case .loading, .failed:
                break // `.loading` and `.failed` should not change the banner visibility
            default:
                self.removeBanner() // All other states should remove the banner
            }
        }
        .store(in: &subscriptions)
    }

    /// Adds a Free Trial bar at the bottom of the container view.
    ///
    private func addBanner(contentText: String) {
        guard let containerView else { return }

        // Remove any previous banner.
        freeTrialBanner?.removeFromSuperview()

        let freeTrialViewController = FreeTrialBannerHostingViewController(mainText: contentText) { [weak self] in
            self?.showUpgradePlanWebView()
        }
        freeTrialViewController.view.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(freeTrialViewController.view)
        NSLayoutConstraint.activate([
            freeTrialViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            freeTrialViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            freeTrialViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // Let consumers know that the layout has been updated so their content is not hidden by the `freeTrialViewController`.
        DispatchQueue.main.async {
            self.onLayoutUpdated(containerView, freeTrialViewController.view.frame.size.height)
        }

        // Store a reference to it to manipulate it later in `removeFreeTrialBanner`.
        freeTrialBanner = freeTrialViewController.view
    }

    /// Removes the Free Trial Banner from the container view..
    ///
    func removeBanner() {
        guard let freeTrialBanner, let containerView else { return }
        freeTrialBanner.removeFromSuperview()
        onLayoutUpdated(containerView, .zero)
        self.freeTrialBanner = nil
    }

    /// Shows a web view for the merchant to update their site plan.
    ///
    func showUpgradePlanWebView() {
        guard let viewController else { return }
        let upgradeController = UpgradePlanCoordinatingController(siteID: siteID, source: .banner, onSuccess: { [weak self] in
            self?.removeBanner() // Removes the banner immediately.
            self?.reloadBannerVisibility() // Reloads the plan again in case the plan didn't update as expected.
        })
        viewController.present(upgradeController, animated: true)
    }
}
