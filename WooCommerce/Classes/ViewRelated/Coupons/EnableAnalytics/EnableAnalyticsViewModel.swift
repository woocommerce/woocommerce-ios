import Foundation
import Yosemite

/// View model for `EnableAnalyticsView`
///
final class EnableAnalyticsViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager

    @Published private(set) var enablingAnalyticsInProgress: Bool = false

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Enables Analytics for the current store
    ///
    func enableAnalytics(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        enablingAnalyticsInProgress = true
        let action = SettingAction.enableAnalyticsSetting(siteID: siteID) { [weak self] result in
            self?.enablingAnalyticsInProgress = false
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                DDLogError("⛔️ Error enabling analytics: \(error)")
                onFailure()
            }
        }
        stores.dispatch(action)
    }
}
