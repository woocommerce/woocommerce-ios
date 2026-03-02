import CocoaLumberjackSwift
import Yosemite
import Foundation
import Storage
import WooFoundation

@Observable
@MainActor
final class POSSettingsLocalCatalogViewModel {
    private(set) var catalogSize: String = ""
    private(set) var lastFullSyncDate: String = ""
    private(set) var lastIncrementalSyncDate: String = ""

    private(set) var isLoading: Bool = false
    private(set) var isRefreshingCatalog: Bool = false
    let deviceHasCellularCapability: Bool = CellularCapabilityChecker.deviceHasCellularCapability()

    var catalogRefreshError: POSIdentifiableErrorState? = nil

    private let siteID: Int64
    private let catalogSettingsService: POSCatalogSettingsServiceProtocol
    private let catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol
    private let siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol
    private let syncStateModel: POSCatalogSyncStateModel
    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter
    }()

    nonisolated(unsafe) private var syncStateObservationTask: Task<Void, Never>?

    private var currentSyncState: POSCatalogSyncState {
        syncStateModel.state[siteID] ?? .syncNeverDone(siteID: siteID)
    }

    var allowFullSyncOnCellular: Bool {
        get {
            siteSettings.getPOSLocalCatalogCellularDataAllowed(siteID: siteID)
        }
        set {
            siteSettings.setPOSLocalCatalogCellularDataAllowed(siteID: siteID, allowed: newValue)
        }
    }

    nonisolated init(siteID: Int64,
                     catalogSettingsService: POSCatalogSettingsServiceProtocol,
                     catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol,
                     siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol? = nil) {
        self.siteID = siteID
        self.catalogSettingsService = catalogSettingsService
        self.catalogSyncCoordinator = catalogSyncCoordinator
        self.syncStateModel = catalogSyncCoordinator.fullSyncStateModel
        self.siteSettings = siteSettings ?? SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage())

        // Observe sync state changes to update UI when sync completes in background.
        // Deferred to a Task because `startObservingSyncState` is MainActor-isolated.
        Task { @MainActor [self] in
            self.startObservingSyncState()
        }
    }

    deinit {
        syncStateObservationTask?.cancel()
    }

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

    func refreshCatalog() async {
        isRefreshingCatalog = true
        catalogRefreshError = nil

        do {
            try await catalogSyncCoordinator.performFullSync(for: siteID, regenerateCatalog: true)
            isRefreshingCatalog = false
            await loadCatalogData()
        } catch {
            DDLogError("⛔️ POSSettingsLocalCatalog: Failed to refresh catalog: \(error)")
            isRefreshingCatalog = false
            catalogRefreshError = POSIdentifiableErrorState(errorState: .errorOnRefreshingCatalog(error: error))
        }
    }

    /// Starts observing sync state changes to update UI when sync completes in background
    private func startObservingSyncState() {
        syncStateObservationTask = Task {
            var previousState = currentSyncState

            while !Task.isCancelled {
                // Wait for the next state change
                await observeNextStateChange()

                // Read the new state after change is detected
                let newState = currentSyncState
                guard newState != previousState else { continue }

                // Handle terminal states when user initiated refresh
                switch newState {
                case .syncCompleted, .syncFailed, .initialSyncFailed:
                    // Sync finished - clear the refreshing state if it was set
                    if isRefreshingCatalog {
                        isRefreshingCatalog = false
                        // Reload catalog data to show updated info
                        await loadCatalogData()
                    }
                case .syncStarted, .initialSyncStarted:
                    // Sync is running - keep spinner active
                    break
                case .syncNeverDone:
                    // No sync has been done
                    break
                }
                previousState = newState
            }
        }
    }

    /// Waits for the next change to the observed sync state.
    /// Re-registers observation each time it's called.
    private func observeNextStateChange() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            withObservationTracking {
                // Access the observed property to register observation
                _ = currentSyncState
            } onChange: {
                // When state changes, resume the continuation
                continuation.resume()
            }
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
            value: "%1$d products and %2$ld variations",
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

struct POSIdentifiableErrorState: Identifiable, Equatable {
    let errorState: PointOfSaleErrorState
    let id = UUID()
}
