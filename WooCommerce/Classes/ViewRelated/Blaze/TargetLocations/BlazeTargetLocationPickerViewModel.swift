import Foundation
import Yosemite

/// View model for `BlazeTargetLocationPickerView`
final class BlazeTargetLocationPickerViewModel: ObservableObject {

    @Published var selectedLocations: Set<BlazeTargetLocation>?

    private let siteID: Int64
    private let stores: StoresManager

    init(selectedLocations: Set<BlazeTargetLocation>? = nil, 
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.selectedLocations = selectedLocations
        self.siteID = siteID
        self.stores = stores
    }
}
