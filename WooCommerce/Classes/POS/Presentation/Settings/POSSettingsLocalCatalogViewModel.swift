import Yosemite
import Foundation

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
    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter
    }()

    init(siteID: Int64,
         catalogSettingsService: POSCatalogSettingsServiceProtocol,
         catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol) {
        self.siteID = siteID
        self.catalogSettingsService = catalogSettingsService
        self.catalogSyncCoordinator = catalogSyncCoordinator
    }

    @MainActor
    func loadCatalogData() async {
        isLoading = true
        defer { isLoading = false }

        async let sizeData = loadCatalogSize()
        async let syncDatesData = loadSyncDates()

        let (size, syncDates) = await (sizeData, syncDatesData)

        catalogSize = size
        lastFullSyncDate = syncDates.full
        lastIncrementalSyncDate = syncDates.incremental
    }

    @MainActor
    func refreshCatalog() async {
        isRefreshingCatalog = true
        defer { isRefreshingCatalog = false }

        do {
            try await catalogSyncCoordinator.performFullSync(for: siteID)
            await loadCatalogData()
        } catch {
            DDLogError("⛔️ POSSettingsLocalCatalog: Failed to refresh catalog: \(error)")
        }
    }
}

private extension POSSettingsLocalCatalogViewModel {
    func loadCatalogSize() async -> String {
        do {
            let statistics = try await catalogSettingsService.loadCatalogStatistics(for: siteID)
            return String(format: Localization.catalogSizeFormat, statistics.productCount, statistics.variationCount)
        } catch {
            DDLogError("⛔️ POSSettingsLocalCatalog: Error loading catalog size: \(error)")
            return Localization.catalogSizeUnavailable
        }
    }

    func loadSyncDates() async -> (full: String, incremental: String) {
        let syncDates = await catalogSettingsService.loadSyncDates(for: siteID)
        let full = formatSyncDate(syncDates.lastFullSyncDate)
        let incremental = formatSyncDate(syncDates.lastIncrementalSyncDate)
        return (full, incremental)
    }

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
            value: "Not synced",
            comment: "Text shown when no sync has been performed yet."
        )
    }
}
