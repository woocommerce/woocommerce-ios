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
    private let viewControllerToPresentShareSheet: UIViewController
    private let featureFlagService: FeatureFlagService

    private var shouldEnableShareProductUsingAI: Bool {
        site?.isWordPressComStore == true && featureFlagService.isFeatureFlagEnabled(.shareProductAI)
    }

    private init(site: Site?,
                 productURL: URL,
                 productName: String,
                 shareSheetAnchorView: UIView?,
                 shareSheetAnchorItem: UIBarButtonItem?,
                 viewControllerToPresentShareSheet: UIViewController,
                 featureFlagService: FeatureFlagService,
                 navigationController: UINavigationController) {
        self.site = site
        self.productURL = productURL
        self.productName = productName
        self.shareSheetAnchorView = shareSheetAnchorView
        self.shareSheetAnchorItem = shareSheetAnchorItem
        self.viewControllerToPresentShareSheet = viewControllerToPresentShareSheet
        self.featureFlagService = featureFlagService
        self.navigationController = navigationController
    }

    convenience init(site: Site? = ServiceLocator.stores.sessionManager.defaultSite,
                     productURL: URL,
                     productName: String,
                     shareSheetAnchorView: UIView,
                     viewControllerToPresentShareSheet: UIViewController,
                     featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     navigationController: UINavigationController) {
        self.init(site: site,
                  productURL: productURL,
                  productName: productName,
                  shareSheetAnchorView: shareSheetAnchorView,
                  shareSheetAnchorItem: nil,
                  viewControllerToPresentShareSheet: viewControllerToPresentShareSheet,
                  featureFlagService: featureFlagService,
                  navigationController: navigationController)
    }

    convenience init(site: Site? = ServiceLocator.stores.sessionManager.defaultSite,
                     productURL: URL,
                     productName: String,
                     shareSheetAnchorItem: UIBarButtonItem,
                     viewControllerToPresentShareSheet: UIViewController,
                     featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     navigationController: UINavigationController) {
        self.init(site: site,
                  productURL: productURL,
                  productName: productName,
                  shareSheetAnchorView: nil,
                  shareSheetAnchorItem: shareSheetAnchorItem,
                  viewControllerToPresentShareSheet: viewControllerToPresentShareSheet,
                  featureFlagService: featureFlagService,
                  navigationController: navigationController)
    }

    func start() {
        if shouldEnableShareProductUsingAI {
            presentShareProductAIGeneration()
        } else {
            presentShareSheet()
        }
    }
}

// MARK: Navigation
private extension ShareProductCoordinator {
    func presentShareSheet() {
        if let shareSheetAnchorView {
            SharingHelper.shareURL(url: productURL,
                                   title: productName,
                                   from: shareSheetAnchorView,
                                   in: viewControllerToPresentShareSheet)
        } else if let shareSheetAnchorItem {
            SharingHelper.shareURL(url: productURL,
                                   title: productName,
                                   from: shareSheetAnchorItem,
                                   in: viewControllerToPresentShareSheet)
        }
    }

    // TODO: 9867 UI to show product sharing message AI generation for eligible sites
    func presentShareProductAIGeneration() {

    }
}
