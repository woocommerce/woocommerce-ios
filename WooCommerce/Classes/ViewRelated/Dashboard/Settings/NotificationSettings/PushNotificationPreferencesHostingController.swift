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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Flush after the transition is finalised so an interactive back-swipe
        // the user then cancels doesn't tear down the save pipeline. Both flags
        // remain valid during `viewDidDisappear`.
        if isMovingFromParent || isBeingDismissed {
            viewModel.flushPendingSaves()
        }
    }
}
