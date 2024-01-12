import Foundation
import Yosemite

/// View model for `BlazeTargetLocationPickerView`
final class BlazeTargetLocationPickerViewModel: ObservableObject {

    @Published var selectedLocations: Set<BlazeTargetLocation>?

    private let siteID: Int64
    private let stores: StoresManager
    private let onCompletion: (Set<BlazeTargetLocation>?) -> Void

    init(siteID: Int64,
         selectedLocations: Set<BlazeTargetLocation>? = nil,
         stores: StoresManager = ServiceLocator.stores,
         onCompletion: @escaping (Set<BlazeTargetLocation>?) -> Void) {
        self.selectedLocations = selectedLocations
        self.siteID = siteID
        self.stores = stores
        self.onCompletion = onCompletion
    }
}
