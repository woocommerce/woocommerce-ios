import Foundation
import Yosemite

/// View model for `StoreNameSetupView`.
///
final class StoreNameSetupViewModel: ObservableObject {

    @Published var name: String
    @Published private(set) var isSavingInProgress = false

    private let siteID: Int64
    private let stores: StoresManager
    private let onNameSaved: () -> Void

    init(siteID: Int64,
         name: String,
         stores: StoresManager = ServiceLocator.stores,
         onNameSaved: @escaping () -> Void) {
        self.siteID = siteID
        self.name = name
        self.stores = stores
        self.onNameSaved = onNameSaved
    }

    func saveName() {
        
    }
}
