import UIKit
import struct Yosemite.Site
import protocol Experiments.FeatureFlagService

/// Coordinates navigation for product sharing
final class ShareProductCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let site: Site?
    private let productURL: URL
    private let productName: String
    private let productDescription: String
    private let shareSheetAnchorView: UIView?
    private let shareSheetAnchorItem: UIBarButtonItem?
    private let shareProductEligibilityChecker: ShareProductAIEligibilityChecker

    private var bottomSheetPresenter: BottomSheetPresenter?

    private init(site: Site?,
                 productURL: URL,
                 productName: String,
                 productDescription: String,
                 shareSheetAnchorView: UIView?,
                 shareSheetAnchorItem: UIBarButtonItem?,
                 featureFlagService: FeatureFlagService,
                 navigationController: UINavigationController) {
        self.site = site
        self.productURL = productURL
        self.productName = productName
        self.productDescription = productDescription
        self.shareSheetAnchorView = shareSheetAnchorView
        self.shareSheetAnchorItem = shareSheetAnchorItem
        self.shareProductEligibilityChecker = DefaultShareProductAIEligibilityChecker(site: site, featureFlagService: featureFlagService)
        self.navigationController = navigationController
    }

    convenience init(site: Site? = ServiceLocator.stores.sessionManager.defaultSite,
                     productURL: URL,
                     productName: String,
                     productDescription: String,
                     shareSheetAnchorView: UIView,
                     featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     navigationController: UINavigationController) {
        self.init(site: site,
                  productURL: productURL,
                  productName: productName,
                  productDescription: productDescription,
                  shareSheetAnchorView: shareSheetAnchorView,
                  shareSheetAnchorItem: nil,
                  featureFlagService: featureFlagService,
                  navigationController: navigationController)
    }

    convenience init(site: Site? = ServiceLocator.stores.sessionManager.defaultSite,
                     productURL: URL,
                     productName: String,
                     productDescription: String,
                     shareSheetAnchorItem: UIBarButtonItem,
                     featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                     navigationController: UINavigationController) {
        self.init(site: site,
                  productURL: productURL,
                  productName: productName,
                  productDescription: productDescription,
                  shareSheetAnchorView: nil,
                  shareSheetAnchorItem: shareSheetAnchorItem,
                  featureFlagService: featureFlagService,
                  navigationController: navigationController)
    }

    func start() {
        if shareProductEligibilityChecker.canGenerateShareProductMessageUsingAI {
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
                                   in: navigationController.topmostPresentedViewController)
        } else if let shareSheetAnchorItem {
            SharingHelper.shareURL(url: productURL,
                                   title: productName,
                                   from: shareSheetAnchorItem,
                                   in: navigationController.topmostPresentedViewController)
        }
    }

    func presentShareProductAIGeneration() {
        guard let siteID = site?.siteID else {
            DDLogWarn("⚠️ No site found for generating product sharing message!")
            return
        }
        let viewModel = ProductSharingMessageGenerationViewModel(siteID: siteID,
                                                                 url: productURL.absoluteString,
                                                                 productName: productName,
                                                                 productDescription: productDescription)
        let controller = ProductSharingMessageGenerationHostingController(viewModel: viewModel)

        let presenter = BottomSheetPresenter(configure: { bottomSheet in
            var sheet = bottomSheet
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.largestUndimmedDetentIdentifier = .none
            sheet.prefersGrabberVisible = true
            sheet.detents = [.medium(), .large()]
        })
        bottomSheetPresenter = presenter
        presenter.present(controller, from: navigationController.topmostPresentedViewController, onDismiss: {
            // TODO: Analytics
        })
    }
}
