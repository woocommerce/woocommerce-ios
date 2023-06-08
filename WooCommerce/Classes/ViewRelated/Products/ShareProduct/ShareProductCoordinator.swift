import UIKit
import struct Yosemite.Site
import protocol Experiments.FeatureFlagService

/// Coordinates navigation for product sharing
final class ShareProductCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let site: Site?
    private let productURL: URL
    private let productName: String
    private let shareSheetAnchorView: UIView?
    private let shareSheetAnchorItem: UIBarButtonItem?
    private let featureFlagService: FeatureFlagService

    private var shouldEnableShareProductUsingAI: Bool {
        site?.isWordPressComStore == true && featureFlagService.isFeatureFlagEnabled(.shareProductAI)
    }

    private var bottomSheetPresenter: BottomSheetPresenter?

    private init(site: Site?,
                 productURL: URL,
                 productName: String,
                 shareSheetAnchorView: UIView?,
                 shareSheetAnchorItem: UIBarButtonItem?,
                 featureFlagService: FeatureFlagService,
                 navigationController: UINavigationController) {
        self.site = site
        self.productURL = productURL
        self.productName = productName
        self.shareSheetAnchorView = shareSheetAnchorView
        self.shareSheetAnchorItem = shareSheetAnchorItem
        self.featureFlagService = featureFlagService
        self.navigationController = navigationController
    }

    convenience init(site: Site? = ServiceLocator.stores.sessionManager.defaultSite,
                     productURL: URL,
                     productName: String,
                     shareSheetAnchorView: UIView,
                     featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     navigationController: UINavigationController) {
        self.init(site: site,
                  productURL: productURL,
                  productName: productName,
                  shareSheetAnchorView: shareSheetAnchorView,
                  shareSheetAnchorItem: nil,
                  featureFlagService: featureFlagService,
                  navigationController: navigationController)
    }

    convenience init(site: Site? = ServiceLocator.stores.sessionManager.defaultSite,
                     productURL: URL,
                     productName: String,
                     shareSheetAnchorItem: UIBarButtonItem,
                     featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     navigationController: UINavigationController) {
        self.init(site: site,
                  productURL: productURL,
                  productName: productName,
                  shareSheetAnchorView: nil,
                  shareSheetAnchorItem: shareSheetAnchorItem,
                  featureFlagService: featureFlagService,
                  navigationController: navigationController)
    }

    func start() {
        if shouldEnableShareProductUsingAI {
            presentShareProductAIGeneration()
        } else {
            presentShareSheetWithURLOnly()
        }
    }
}

// MARK: Navigation
private extension ShareProductCoordinator {
    func presentShareSheetWithURLOnly() {
        if let shareSheetAnchorView {
            SharingHelper.shareURL(url: productURL,
                                   title: productName,
                                   from: shareSheetAnchorView,
                                   in: navigationController.topmostPresentedViewController) { activityType, completed, _, _ in
                if completed, let activityType {
                    DDLogInfo("✅ Sharing completed with \(activityType)")
                    // TODO: Analytics
                }
            }
        } else if let shareSheetAnchorItem {
            SharingHelper.shareURL(url: productURL,
                                   title: productName,
                                   from: shareSheetAnchorItem,
                                   in: navigationController.topmostPresentedViewController) { activityType, completed, _, _ in
                if completed, let activityType {
                    DDLogInfo("✅ Sharing completed with \(activityType)")
                    // TODO: Analytics
                }
            }
        }
    }

    func presentShareSheet(with message: String) {
        guard message.isNotEmpty else {
            return presentShareSheetWithURLOnly()
        }

        if let shareSheetAnchorView {
            SharingHelper.shareMessage(message,
                                       from: shareSheetAnchorView,
                                       in: navigationController.topmostPresentedViewController) { activityType, completed, _, _ in
                if completed, let activityType {
                    DDLogInfo("✅ Sharing completed with \(activityType)")
                    // TODO: Analytics
                }
            }
        } else if let shareSheetAnchorItem {
            SharingHelper.shareMessage(message,
                                       from: shareSheetAnchorItem,
                                       in: navigationController.topmostPresentedViewController) { activityType, completed, _, _ in
                if completed, let activityType {
                    DDLogInfo("✅ Sharing completed with \(activityType)")
                    // TODO: Analytics
                }
            }
        }
    }

    func presentShareProductAIGeneration() {
        guard let siteID = site?.siteID else {
            DDLogWarn("⚠️ No site found for generating product sharing message!")
            return
        }
        let viewModel = ProductSharingMessageGenerationViewModel(siteID: siteID, productName: productName, url: productURL.absoluteString)
        let controller = ProductSharingMessageGenerationHostingController(viewModel: viewModel) { [weak self] message in
            self?.navigationController.topmostPresentedViewController.dismiss(animated: true) {
                self?.presentShareSheet(with: message)
            }
            // TODO: Analytics
        } onDismiss: { [weak self] in
            // TODO: Analytics
            self?.navigationController.topmostPresentedViewController.dismiss(animated: true)
        }

        let presenter = BottomSheetPresenter(configure: { bottomSheet in
            var sheet = bottomSheet
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.largestUndimmedDetentIdentifier = .none
            sheet.prefersGrabberVisible = true
            sheet.detents = [.medium(), .large()]
        })
        bottomSheetPresenter = presenter
        presenter.present(UINavigationController(rootViewController: controller),
                          from: navigationController.topmostPresentedViewController,
                          onDismiss: {
            // TODO: Analytics
        })
    }
}
