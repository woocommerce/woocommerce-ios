import CocoaLumberjackSwift
import Yosemite
import Foundation
import Storage

@Observable
final class POSSettingsLocalCatalogViewModel {
    private(set) var catalogSize: String = ""
    private(set) var lastFullSyncDate: String = ""
    private(set) var lastIncrementalSyncDate: String = ""

    private(set) var isLoading: Bool = false
    private(set) var isRefreshingCatalog: Bool = false

    private let siteID: Int64
    private let catalogSettingsService: POSCatalogSettingsServiceProtocol
    private let catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol
    private let siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol
    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter
    }()

    var allowFullSyncOnCellular: Bool {
        get {
            siteSettings.getPOSLocalCatalogCellularDataAllowed(siteID: siteID)
        }
        set {
            siteSettings.setPOSLocalCatalogCellularDataAllowed(siteID: siteID, allowed: newValue)
        }
    }

    init(siteID: Int64,
         catalogSettingsService: POSCatalogSettingsServiceProtocol,
         catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol,
         siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol? = nil) {
        self.siteID = siteID
        self.catalogSettingsService = catalogSettingsService
        self.catalogSyncCoordinator = catalogSyncCoordinator
        self.siteSettings = siteSettings ?? SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage())
    }

    @MainActor
    func loadCatalogData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let catalogInfo = try await catalogSettingsService.loadCatalogInfo(for: siteID)
            catalogSize = String(format: Localization.catalogSizeFormat, catalogInfo.productCount, catalogInfo.variationCount)
            lastFullSyncDate = formatSyncDate(catalogInfo.lastFullSyncDate)
            lastIncrementalSyncDate = formatSyncDate(catalogInfo.lastIncrementalSyncDate)
        } catch {
            DDLogError("⛔️ POSSettingsLocalCatalog: Error loading catalog data: \(error)")
            catalogSize = Localization.catalogSizeUnavailable
            lastFullSyncDate = Localization.syncDateUnavailable
            lastIncrementalSyncDate = Localization.syncDateUnavailable
        }
    }

    @MainActor
    func refreshCatalog() async {
        isRefreshingCatalog = true
        defer { isRefreshingCatalog = false }

        do {
            try await catalogSyncCoordinator.performFullSync(for: siteID, regenerateCatalog: true)
            await loadCatalogData()
        } catch {
            DDLogError("⛔️ POSSettingsLocalCatalog: Failed to refresh catalog: \(error)")
        }
    }
}

private extension POSSettingsLocalCatalogViewModel {
    func formatSyncDate(_ date: Date?) -> String {
        guard let date else { return Localization.neverSynced }
        return dateFormatter.localizedString(for: date, relativeTo: Date())
    }
}

private extension POSSettingsLocalCatalogViewModel {
    enum Localization {
        static let catalogSizeFormat = NSLocalizedString(
            "posSettingsLocalCatalogViewModel.catalogSizeFormat",
            value: "%1$d products, %2$ld variations",
            comment: "Format string for catalog size showing product count and variation count. " +
            "%1$d will be replaced by the product count, and %2$ld will be replaced by the variation count."
        )

        static let catalogSizeUnavailable = NSLocalizedString(
            "posSettingsLocalCatalogViewModel.catalogSizeUnavailable",
            value: "Catalog size unavailable",
            comment: "Text shown when catalog size cannot be determined."
        )

        static let neverSynced = NSLocalizedString(
            "posSettingsLocalCatalogViewModel.neverSynced",
            value: "Not updated",
            comment: "Text shown when no update has been performed yet."
        )

        static let syncDateUnavailable = NSLocalizedString(
            "posSettingsLocalCatalogViewModel.syncDateUnavailable",
            value: "Update date unavailable",
            comment: "Text shown when update date cannot be determined."
        )
    }
}
