import Foundation
import Yosemite

// MARK: - AnalyticsViewModel
//
class AnalyticsViewModel: ObservableObject {
    private let stores: StoresManager
    @Published var selectedRange: String = "Today"

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func saveSelectedDateRange(siteID: Int64, range: String) {
        let saveSelectedDateRangeAction = AppSettingsAction.setSelectedDateRange(siteID: siteID, range: range)
        stores.dispatch(saveSelectedDateRangeAction)
    }

    func getSelectedDateRange(siteID: Int64) {
        let action = AppSettingsAction.getSelectedDateRange(siteID: siteID) { [weak self] range in
            guard let self = self else { return }
            self.selectedRange = range
        }
        stores.dispatch(action)
    }
}
