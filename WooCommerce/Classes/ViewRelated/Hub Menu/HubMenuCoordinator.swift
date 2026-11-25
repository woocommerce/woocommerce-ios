import UIKit
import struct Yosemite.ProductReviewFromNoteParcel
import protocol Yosemite.StoresManager

/// Coordinator for the HubMenu tab.
final class HubMenuCoordinator {
    let tabContainerController: TabContainerController
    var hubMenuController: HubMenuViewController?

    private let storesManager: StoresManager
    private let httpsConfigurationWarningViewModel: HTTPSConfigurationWarningViewModel
    private let tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker

    init(tabContainerController: TabContainerController,
         storesManager: StoresManager,
         httpsConfigurationWarningViewModel: HTTPSConfigurationWarningViewModel,
         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker) {
        self.tabContainerController = tabContainerController
        self.storesManager = storesManager
        self.httpsConfigurationWarningViewModel = httpsConfigurationWarningViewModel
        self.tapToPayBadgePromotionChecker = tapToPayBadgePromotionChecker
    }

    @MainActor
    func activate(siteID: Int64) {
        let hubMenuController = HubMenuViewController(siteID: siteID,
                                                      stores: storesManager,
                                                      httpsConfigurationWarningViewModel: httpsConfigurationWarningViewModel,
                                                      tapToPayBadgePromotionChecker: tapToPayBadgePromotionChecker)
        self.hubMenuController = hubMenuController
        tabContainerController.wrappedController = UINavigationController(rootViewController: hubMenuController)
    }

    func showReview(_ review: ProductReviewFromNoteParcel) {
        hubMenuController?.pushReviewDetailsViewController(using: review)
    }
}

extension HubMenuCoordinator: DeepLinkNavigator {
    func navigate(to destination: any DeepLinkDestinationProtocol) {
        hubMenuController?.navigate(to: destination)
    }
}
