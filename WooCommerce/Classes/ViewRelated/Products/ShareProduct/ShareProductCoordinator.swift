import UIKit
import struct Yosemite.Site
import protocol Experiments.FeatureFlagService
import protocol WooFoundation.Analytics

/// Coordinates navigation for product sharing
final class ShareProductCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let siteID: Int64
    private let productURL: URL
    private let productName: String
    private let productDescription: String
    private let shareSheetAnchorView: UIView?
    private let shareSheetAnchorItem: UIBarButtonItem?
    private let eligibilityChecker: ShareProductAIEligibilityChecker
    private let analytics: Analytics

    private var bottomSheetPresenter: BottomSheetPresenter?

    private init(siteID: Int64,
                 productURL: URL,
                 productName: String,
                 productDescription: String,
                 shareSheetAnchorView: UIView?,
                 shareSheetAnchorItem: UIBarButtonItem?,
                 eligibilityChecker: ShareProductAIEligibilityChecker,
                 navigationController: UINavigationController,
                 analytics: Analytics) {
        self.siteID = siteID
        self.productURL = productURL
        self.productName = productName
        self.productDescription = productDescription
        self.shareSheetAnchorView = shareSheetAnchorView
        self.shareSheetAnchorItem = shareSheetAnchorItem
        self.eligibilityChecker = eligibilityChecker
        self.navigationController = navigationController
        self.analytics = analytics
    }

    convenience init(siteID: Int64,
                     productURL: URL,
                     productName: String,
                     productDescription: String,
                     shareSheetAnchorView: UIView,
                     eligibilityChecker: ShareProductAIEligibilityChecker = DefaultShareProductAIEligibilityChecker(),
                     navigationController: UINavigationController,
                     analytics: Analytics = ServiceLocator.analytics) {
        self.init(siteID: siteID,
                  productURL: productURL,
                  productName: productName,
                  productDescription: productDescription,
                  shareSheetAnchorView: shareSheetAnchorView,
                  shareSheetAnchorItem: nil,
                  eligibilityChecker: eligibilityChecker,
                  navigationController: navigationController,
                  analytics: analytics)
    }

    convenience init(siteID: Int64,
                     productURL: URL,
                     productName: String,
                     productDescription: String,
                     shareSheetAnchorItem: UIBarButtonItem,
                     eligibilityChecker: ShareProductAIEligibilityChecker = DefaultShareProductAIEligibilityChecker(),
                     navigationController: UINavigationController,
                     analytics: Analytics = ServiceLocator.analytics) {
        self.init(siteID: siteID,
                  productURL: productURL,
                  productName: productName,
                  productDescription: productDescription,
                  shareSheetAnchorView: nil,
                  shareSheetAnchorItem: shareSheetAnchorItem,
                  eligibilityChecker: eligibilityChecker,
                  navigationController: navigationController,
                  analytics: analytics)
    }

    func start() {
        if eligibilityChecker.canGenerateShareProductMessageUsingAI {
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
        presenter.present(controller, from: navigationController.topmostPresentedViewController, onDismiss: { [weak self] in
            self?.analytics.track(event: .ProductSharingAI.sheetDismissed())
        })
        analytics.track(event: .ProductSharingAI.sheetDisplayed())
    }
}
