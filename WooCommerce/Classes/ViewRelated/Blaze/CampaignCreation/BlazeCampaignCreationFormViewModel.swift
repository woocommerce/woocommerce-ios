import Foundation
import Yosemite

/// View model for `BlazeCampaignCreationForm`
final class BlazeCampaignCreationFormViewModel: ObservableObject {
    
    private let siteID: Int64
    private let stores: StoresManager
    private let completionHandler: () -> Void

    let budgetSettingViewModel = BlazeBudgetSettingViewModel()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
        self.stores = stores
        self.completionHandler = onCompletion
    }
}
