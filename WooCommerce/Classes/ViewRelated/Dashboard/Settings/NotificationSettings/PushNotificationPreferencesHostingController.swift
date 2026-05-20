import SwiftUI
import Yosemite

final class PushNotificationPreferencesHostingController: UIHostingController<PushNotificationPreferencesView> {
    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        let viewModel = PushNotificationPreferencesViewModel(siteID: siteID, stores: stores)
        super.init(rootView: PushNotificationPreferencesView(viewModel: viewModel))
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
