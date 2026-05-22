import Foundation
import Observation
import Yosemite
import protocol Storage.StorageManagerType

/// State of the store-wide low-stock threshold row.
///
enum LowStockThresholdState: Equatable {
    /// First load, nothing cached yet.
    case loading
    /// Loaded; `.value(nil)` means the setting is absent, non-integer, or the
    /// sync failed without delivering data.
    case value(Int?)
}

/// View model for `NewStockNotificationPreferencesDetailView`. Owns screen-local
/// state that isn't part of the shared `PushNotificationPreferencesViewModel`,
/// starting with the store-wide low-stock threshold row.
///
@MainActor
@Observable
final class NewStockNotificationPreferencesDetailViewModel {

    // MARK: - Low stock threshold

    private(set) var lowStockThresholdState: LowStockThresholdState = .loading

    var onTapEditStoreWideThreshold: (() -> Void)?

    /// `nil` when no admin URL was supplied at construction time.
    var editStoreWideThresholdURL: URL? {
        guard let siteAdminURL else { return nil }
        return siteAdminURL
            .appendingPathComponent("admin.php")
            .appending(queryItems: [
                URLQueryItem(name: "page", value: "wc-settings"),
                URLQueryItem(name: "tab", value: "products"),
                URLQueryItem(name: "section", value: "inventory")
            ])
    }

    // MARK: - Dependencies

    private let siteID: Int64
    private let stores: StoresManager
    private let siteAdminURL: URL?
    @ObservationIgnored
    private let lowStockThresholdResultsController: ResultsController<StorageSiteSetting>

    init(siteID: Int64,
         siteAdminURL: URL?,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.siteAdminURL = siteAdminURL
        self.stores = stores
        let predicate = NSPredicate(format: "siteID == %ld AND settingID == %@",
                                    siteID, Self.lowStockAmountKey)
        let sortDescriptor = NSSortDescriptor(keyPath: \StorageSiteSetting.settingID, ascending: true)
        self.lowStockThresholdResultsController = ResultsController<StorageSiteSetting>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: [sortDescriptor])
        configureLowStockThresholdResultsController()
    }

    /// Screen `.task` hook. Triggers any refresh work owned by this VM.
    func onAppear() async {
        await refreshLowStockThreshold()
    }

    /// Drives `synchronizeProductSiteSettings`. The new value flows in via the
    /// `ResultsController`. Errors are logged silently — when sync fails or
    /// returns no data, the row falls back to the cached value, or to
    /// `.value(nil)` (which renders the inline "view store-wide threshold"
    /// fallback copy) if nothing is cached.
    func refreshLowStockThreshold() async {
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                stores.dispatch(SettingAction.synchronizeProductSiteSettings(siteID: siteID) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                })
            }
        } catch {
            DDLogError("⛔️ Error syncing product site settings for siteID=\(siteID): \(error)")
        }
        // Whether the sync succeeded, returned no data, or threw, resolve
        // `.loading` to whatever's in storage (which may still be nil).
        if case .loading = lowStockThresholdState {
            lowStockThresholdState = .value(readCachedLowStockThreshold())
        }
    }
}

private extension NewStockNotificationPreferencesDetailViewModel {
    static let lowStockAmountKey = "woocommerce_notify_low_stock_amount"

    func configureLowStockThresholdResultsController() {
        lowStockThresholdResultsController.onDidChangeContent = { [weak self] in
            self?.applyLowStockThresholdStorageValue()
        }
        // `StorageManagerDidResetStorage` can be posted from a background
        // thread, so hop to main before mutating @Observable state.
        lowStockThresholdResultsController.onDidResetContent = { [weak self] in
            DispatchQueue.main.async { self?.applyLowStockThresholdStorageValue() }
        }
        do {
            try lowStockThresholdResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching cached low stock threshold for siteID=\(siteID): \(error)")
        }
        applyLowStockThresholdStorageValue()
    }

    /// Reflects the latest storage value into `lowStockThresholdState`.
    func applyLowStockThresholdStorageValue() {
        let hasStoredRow = !lowStockThresholdResultsController.fetchedObjects.isEmpty
        switch lowStockThresholdState {
        case .loading where !hasStoredRow:
            // No row in storage yet — wait for the network sync to resolve.
            // (A row that exists but holds a non-Int value still transitions
            // out of loading; `readCachedLowStockThreshold` returns nil and the
            // row renders the "value unavailable" fallback.)
            return
        default:
            lowStockThresholdState = .value(readCachedLowStockThreshold())
        }
    }

    func readCachedLowStockThreshold() -> Int? {
        guard let raw = lowStockThresholdResultsController.fetchedObjects.first?.value else { return nil }
        return Int(raw)
    }
}
