import Gridicons
import UIKit

/// Generates top banner view that is shown at the top of Dashboard UI.
///
final class DashboardTopBannerFactory {
    static func deprecatedStatsBannerView() -> TopBannerView {
        let viewModel = TopBannerViewModel(title: DeprecatedStatsConstants.title,
                                           infoText: DeprecatedStatsConstants.info,
                                           icon: DeprecatedStatsConstants.icon,
                                           isExpanded: true,
                                           topButton: .chevron(handler: nil))
        return TopBannerView(viewModel: viewModel)
    }
}

private extension DashboardTopBannerFactory {
    enum DeprecatedStatsConstants {
        static let title = NSLocalizedString("Upgrade to keep seeing your stats", comment: "Banner title in my store when stats will be deprecated")
        static let info = NSLocalizedString(
            "We’ve rolled out improvements to our analytics. Upgrade to WooCommerce 4.0 or above or install WooCommerce Admin plugin to keep seeing " +
            "your stats after September 1, 2020.",
            comment: "Banner caption in my store when the stats will be deprecated")
        static let icon = UIImage.syncImage
    }
}
