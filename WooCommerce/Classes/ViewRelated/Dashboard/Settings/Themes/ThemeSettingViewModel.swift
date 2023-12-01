import Foundation
import Yosemite

/// View model for `ThemeSettingView`
/// 
final class ThemeSettingViewModel: ObservableObject {

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    init(siteID: Int64, 
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
    }
}
