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

    func saveName(onCompletion: @escaping () -> Void) {
        errorMessage = nil
        isSavingInProgress = true
        stores.dispatch(SiteAction.updateSiteTitle(siteID: siteID, title: name, completion: { [weak self] result in
            guard let self else { return }
            self.isSavingInProgress = false
            switch result {
            case .success(let site):
                self.stores.updateDefaultStore(site)
                onCompletion()
            case .failure(let error):
                errorMessage = error.localizedDescription
                DDLogError("⛔️ Error saving store name: \(error)")
            }
        }))
    }
}
