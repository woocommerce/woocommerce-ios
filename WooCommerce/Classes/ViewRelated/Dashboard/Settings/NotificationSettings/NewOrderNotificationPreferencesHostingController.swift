import SwiftUI

/// Hosts `NewOrderNotificationPreferencesDetailView`. Navigation chrome
/// (Save, back button, discard alert, saving spinner) is inherited from
/// `NotificationDetailHostingController`.
///
final class NewOrderNotificationPreferencesHostingController:
    NotificationDetailHostingController<NewOrderNotificationPreferencesDetailView> {

    init(viewModel: PushNotificationPreferencesViewModel) {
        super.init(viewModel: viewModel,
                   rootView: NewOrderNotificationPreferencesDetailView(viewModel: viewModel),
                   onDiscard: { [weak viewModel] in viewModel?.discardStoreOrderEdits() })
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
