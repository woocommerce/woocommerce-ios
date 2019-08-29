import Gridicons
import UIKit

/// Generates top banner view that is shown when the eligible stats version is from v3 to v4 and v4 to v3.
///
final class DashboardTopBannerFactory {
    static func v3ToV4BannerView(actionHandler: @escaping () -> Void,
                                 dismissHandler: @escaping () -> Void) -> TopBannerView {
        let viewModel = TopBannerViewModel(title: V3ToV4BannerConstants.title,
                                           infoText: V3ToV4BannerConstants.info,
                                           icon: V3ToV4BannerConstants.icon,
                                           actionButtonTitle: V3ToV4BannerConstants.actionTitle,
                                           actionHandler: actionHandler,
                                           dismissHandler: dismissHandler)
        return TopBannerView(viewModel: viewModel)
    }

    static func v4ToV3BannerView(actionHandler: @escaping () -> Void,
                                 dismissHandler: @escaping () -> Void) -> TopBannerView {
        let viewModel = TopBannerViewModel(title: V4ToV3BannerConstants.title,
                                           infoText: V4ToV3BannerConstants.info,
                                           icon: V4ToV3BannerConstants.icon,
                                           actionButtonTitle: V4ToV3BannerConstants.actionTitle,
                                           actionHandler: actionHandler,
                                           dismissHandler: dismissHandler)
        return TopBannerView(viewModel: viewModel)
    }
}

private extension DashboardTopBannerFactory {
    enum V3ToV4BannerConstants {
        static let title =
            NSLocalizedString("Try our improved stats", comment: "The title of the top banner on Dashboard that indicates new stats is available")
        static let info = NSLocalizedString("We’re rolling out improvements to stats for stores using the WooCommerce Admin plugin",
                                            comment: "The info of the top banner on Dashboard that indicates new stats is available")
        // TODO-1232: update with the new `gift` icon, and draw a red dot at the top right
        static let icon = Gridicon.iconOfType(.addImage, withSize: CGSize(width: 24, height: 24)).imageWithTintColor(StyleManager.wooGreyTextMin)
        static let actionTitle = NSLocalizedString("Try It Now",
                                                   comment: "The action of the top banner on Dashboard that indicates new stats is available")
    }

    enum V4ToV3BannerConstants {
        static let title: String? = nil
        static let info = NSLocalizedString("We have reverted to the old stats as we couldn’t find the WooCommerce Admin plugin",
                                            comment: "The info of the top banner on Dashboard that indicates new stats is unavailable")
        static let icon = Gridicon.iconOfType(.info, withSize: CGSize(width: 24, height: 24)).imageWithTintColor(StyleManager.wooGreyTextMin)
        static let actionTitle = NSLocalizedString("Learn more",
                                                   comment: "The action of the top banner on Dashboard that indicates new stats is unavailable")
    }
}
