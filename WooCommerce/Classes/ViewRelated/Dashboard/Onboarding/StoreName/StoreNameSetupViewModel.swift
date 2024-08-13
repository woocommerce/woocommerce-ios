import Foundation
import Yosemite

/// View model for `StoreNameSetupView`.
///
final class StoreNameSetupViewModel: ObservableObject {

    @Published var name: String
    @Published private(set) var isSavingInProgress = false
    @Published private(set) var errorMessage: String?

    /// Whether the Save button should be enabled
    var shouldEnableSaving: Bool {
        name.isNotEmpty && name != initialStoreName
    }

    private let siteID: Int64
    private let stores: StoresManager
    private let onNameSaved: () -> Void
    private let initialStoreName: String

    init(siteID: Int64,
         name: String,
         stores: StoresManager = ServiceLocator.stores,
         onNameSaved: @escaping () -> Void) {
        self.siteID = siteID
        self.name = name
        self.initialStoreName = name
        self.stores = stores
        self.onNameSaved = onNameSaved
    }

    @MainActor
    func saveName() async {
        errorMessage = nil
        isSavingInProgress = true
        do {
            try await updateStoreName(name)
            // saves default store info to display the new store name on the My Store screen immediately.
            if let site = stores.sessionManager.defaultSite {
                let updatedSite = site.copy(name: name)
                stores.updateDefaultStore(updatedSite)
            }
            onNameSaved()
        } catch {
            errorMessage = error.localizedDescription
            DDLogError("⛔️ Error saving store name: \(error)")
        }
        isSavingInProgress = false
    }
}

private extension StoreNameSetupViewModel {
    @MainActor
    func updateStoreName(_ name: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(SiteAction.updateSiteTitle(siteID: siteID, title: name, completion: { result in
                continuation.resume(with: result)
            }))
        }
    }
}
