import UIKit
import Yosemite

// MARK: - Mediators Protocols
//
/// Encapsulates configuration and interaction of a UITableView section header.
protocol ProductSettingsSectionMediator {
    var title: String { get }
    var rows: [ProductSettingsRowMediator] { get }

    init(_ settings: ProductSettings, productType: ProductType, isEditProductsRelease3Enabled: Bool)
}

// MARK: - Sections declaration for Product Settings
//
enum ProductSettingsSections {
    /// Publish Settings section
    struct PublishSettings: ProductSettingsSectionMediator {
        let title = NSLocalizedString("Publish Settings", comment: "Title of the Publish Settings section on Product Settings screen")

        let rows: [ProductSettingsRowMediator]

        init(_ settings: ProductSettings, productType: ProductType, isEditProductsRelease3Enabled: Bool) {
            if isEditProductsRelease3Enabled && productType == .simple {
                rows = [ProductSettingsRows.Status(settings),
                        ProductSettingsRows.Visibility(settings),
                        ProductSettingsRows.CatalogVisibility(settings),
                        ProductSettingsRows.VirtualProduct(settings),
                        ProductSettingsRows.DownloadableProduct(settings)]
            } else {
                rows = [ProductSettingsRows.Status(settings),
                        ProductSettingsRows.Visibility(settings),
                        ProductSettingsRows.CatalogVisibility(settings)]
            }
        }
    }

    /// More Settings section
    struct MoreOptions: ProductSettingsSectionMediator {
        let title = NSLocalizedString("More Options", comment: "Title of the More Options section on Product Settings screen")

        let rows: [ProductSettingsRowMediator]

        init(_ settings: ProductSettings, productType: ProductType, isEditProductsRelease3Enabled: Bool) {
            if isEditProductsRelease3Enabled {
                rows = [ProductSettingsRows.ReviewsAllowed(settings),
                        ProductSettingsRows.Slug(settings),
                        ProductSettingsRows.PurchaseNote(settings),
                        ProductSettingsRows.MenuOrder(settings)]
            }
            else {
                rows = [ProductSettingsRows.Slug(settings),
                        ProductSettingsRows.PurchaseNote(settings),
                        ProductSettingsRows.MenuOrder(settings)]
            }
        }
    }
}
