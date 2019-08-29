import Gridicons
import UIKit

final class DashboardTopBannerFactory {
    static func v3ToV4BannerViewModel(actionHandler: @escaping () -> Void,
                                      dismissHandler: @escaping () -> Void) -> TopBannerViewModel {
        return TopBannerViewModel(title: V3ToV4BannerConstants.title,
                                  infoText: V3ToV4BannerConstants.info,
                                  icon: V3ToV4BannerConstants.icon,
                                  actionButtonTitle: V3ToV4BannerConstants.actionTitle,
                                  actionHandler: actionHandler,
                                  dismissHandler: dismissHandler)
    }

    static func v4ToV3BannerViewModel(actionHandler: @escaping () -> Void,
                                      dismissHandler: @escaping () -> Void) -> TopBannerViewModel {
        return TopBannerViewModel(title: V4ToV3BannerConstants.title,
                                  infoText: V4ToV3BannerConstants.info,
                                  icon: V4ToV3BannerConstants.icon,
                                  actionButtonTitle: V4ToV3BannerConstants.actionTitle,
                                  actionHandler: actionHandler,
                                  dismissHandler: dismissHandler)
    }
}

extension DashboardTopBannerFactory {
    enum V3ToV4BannerConstants {
        static let title =
            NSLocalizedString("Try our improved stats", comment: "The title of the top banner on Dashboard that indicates new stats is available")
        static let info = NSLocalizedString("We’re rolling out improvements to stats for stores using the WooCommerce Admin plugin",
                                            comment: "The info of the top banner on Dashboard that indicates new stats is available")
        // TODO-jc: update
        static let icon = Gridicon.iconOfType(.addImage, withSize: CGSize(width: 24, height: 24))
        static let actionTitle = NSLocalizedString("Try It Now",
                                                   comment: "The action of the top banner on Dashboard that indicates new stats is available")
    }

    enum V4ToV3BannerConstants {
        static let title: String? = nil
        static let info = NSLocalizedString("We have reverted to the old stats as we couldn’t find the WooCommerce Admin plugin",
                                            comment: "The info of the top banner on Dashboard that indicates new stats is unavailable")
        // TODO-jc: update
        static let icon = Gridicon.iconOfType(.info, withSize: CGSize(width: 24, height: 24))
        static let actionTitle = NSLocalizedString("Learn more",
                                                   comment: "The action of the top banner on Dashboard that indicates new stats is unavailable")
    }
}
