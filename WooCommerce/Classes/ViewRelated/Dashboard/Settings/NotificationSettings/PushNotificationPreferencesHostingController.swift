import SwiftUI
import Yosemite

final class PushNotificationPreferencesHostingController: UIHostingController<PushNotificationPreferencesView> {
    private let viewModel: PushNotificationPreferencesViewModel

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        let viewModel = PushNotificationPreferencesViewModel(siteID: siteID, stores: stores)
        self.viewModel = viewModel
        super.init(rootView: PushNotificationPreferencesView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only flush when the screen is actually leaving the stack — `viewWillDisappear`
        // also fires when another screen is pushed on top, and we don't want to end
        // the debounce queue in that case.
        if isMovingFromParent || isBeingDismissed {
            viewModel.flushPendingSaves()
        }
    }
}
