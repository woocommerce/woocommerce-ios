import Observation
import Yosemite

/// View model for `AnalyticsUpdateModeBottomSheet`.
@MainActor
@Observable
final class AnalyticsUpdateModeBottomSheetViewModel {
    private(set) var selectedMode: AnalyticsImportUpdateMode?
    private(set) var updatingMode: AnalyticsImportUpdateMode?

    var isUpdating: Bool {
        updatingMode != nil
    }

    private let siteID: Int64
    private let stores: StoresManager
    private let onModeUpdated: @MainActor (AnalyticsImportUpdateMode) -> Void

    init(siteID: Int64,
         selectedMode: AnalyticsImportUpdateMode?,
         stores: StoresManager = ServiceLocator.stores,
         onModeUpdated: @escaping @MainActor (AnalyticsImportUpdateMode) -> Void) {
        self.siteID = siteID
        self.selectedMode = selectedMode
        self.stores = stores
        self.onModeUpdated = onModeUpdated
    }

    func handleSelection(_ mode: AnalyticsImportUpdateMode) async throws -> Bool {
        if selectedMode == mode {
            return true
        }

        guard updatingMode == nil else { return false }

        updatingMode = mode
        defer { updatingMode = nil }

        do {
            try await updateAnalyticsImportUpdateMode(mode)
            selectedMode = mode
            onModeUpdated(mode)
            return true
        } catch {
            DDLogError("Error updating analytics import update mode: \(error)")
            throw error
        }
    }
}

private extension AnalyticsUpdateModeBottomSheetViewModel {
    func updateAnalyticsImportUpdateMode(_ mode: AnalyticsImportUpdateMode) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let action = SettingAction.updateAnalyticsImportUpdateMode(siteID: siteID, value: mode) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }
}
