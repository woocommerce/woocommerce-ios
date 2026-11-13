import SwiftUI

/// Hosts `NewOrderNotificationPreferencesDetailView`.
final class NewOrderNotificationPreferencesHostingController:
    NotificationDetailHostingController<NewOrderNotificationPreferencesDetailView> {

    init(viewModel: PushNotificationPreferencesViewModel) {
        super.init(viewModel: viewModel,
                   rootView: NewOrderNotificationPreferencesDetailView(viewModel: viewModel),
                   notificationType: .newOrder,
                   onDiscard: { [weak viewModel] in viewModel?.discardStoreOrderEdits() })
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
