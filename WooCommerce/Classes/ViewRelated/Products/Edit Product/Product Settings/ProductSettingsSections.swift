import UIKit
import Yosemite

// MARK: - Mediators Protocols
//
/// Encapsulates configuration and interaction of a UITableView section header.
protocol ProductSettingsSectionMediator {
    var title: String { get }
    var rows: [ProductSettingsRowMediator] { get }

    init(_ settings: ProductSettings)
}

// MARK: - Sections declaration for Product Settings
//
enum ProductSettingsSections {
    /// Publish Settings section
    struct PublishSettings: ProductSettingsSectionMediator {
        let title = NSLocalizedString("Publish Settings", comment: "Title of the Publish Settings section on Product Settings screen")

        let rows: [ProductSettingsRowMediator]

        init(_ settings: ProductSettings) {
            let shouldShowVirtualProductSetting = settings.productType == .simple || settings.productType == .subscription
            let shouldShowDownloadableProductSetting = settings.productType == .simple || settings.productType == .subscription
            let rows: [ProductSettingsRowMediator?] = [ProductSettingsRows.Status(settings),
                                                       ProductSettingsRows.Visibility(settings),
                                                       ProductSettingsRows.CatalogVisibility(settings),
                                                       shouldShowVirtualProductSetting ? ProductSettingsRows.VirtualProduct(settings) : nil,
                                                       shouldShowDownloadableProductSetting ? ProductSettingsRows.DownloadableProduct(settings) : nil]
            self.rows = rows.compactMap { $0 }
        }
    }

    /// More Settings section
    struct MoreOptions: ProductSettingsSectionMediator {
        let title = NSLocalizedString("More Options", comment: "Title of the More Options section on Product Settings screen")

        let rows: [ProductSettingsRowMediator]

        init(_ settings: ProductSettings) {
            rows = [ProductSettingsRows.ReviewsAllowed(settings),
            ProductSettingsRows.Slug(settings),
            ProductSettingsRows.PurchaseNote(settings),
            ProductSettingsRows.MenuOrder(settings)]
        }
    }
}
