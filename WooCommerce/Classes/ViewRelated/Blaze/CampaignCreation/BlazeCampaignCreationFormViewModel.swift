import Foundation
import Yosemite

/// View model for `BlazeCampaignCreationForm`
final class BlazeCampaignCreationFormViewModel: ObservableObject {

    private let siteID: Int64
    private let stores: StoresManager
    private let completionHandler: () -> Void

    // Budget details
    private var startDate = Date.now
    private var dailyBudget = BlazeBudgetSettingViewModel.Constants.minimumDailyAmount
    private var duration = BlazeBudgetSettingViewModel.Constants.defaultDayCount

    var budgetSettingViewModel: BlazeBudgetSettingViewModel {
        BlazeBudgetSettingViewModel(dailyBudget: dailyBudget, duration: duration, startDate: startDate) { [weak self] dailyBudget, duration, startDate in
            guard let self else { return }
            self.startDate = startDate
            self.duration = duration
            self.startDate = startDate
        }
    }

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
        self.stores = stores
        self.completionHandler = onCompletion
    }
}
