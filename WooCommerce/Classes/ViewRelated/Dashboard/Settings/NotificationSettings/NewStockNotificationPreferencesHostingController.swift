import SwiftUI

/// Hosts `NewStockNotificationPreferencesDetailView`. Navigation chrome
/// (Save, back button, discard alert, saving spinner) is inherited from
/// `NotificationDetailHostingController`.
///
final class NewStockNotificationPreferencesHostingController:
    NotificationDetailHostingController<NewStockNotificationPreferencesDetailView> {

    init(viewModel: PushNotificationPreferencesViewModel) {
        super.init(viewModel: viewModel,
                   rootView: NewStockNotificationPreferencesDetailView(viewModel: viewModel),
                   notificationType: .stockAlert,
                   onDiscard: { [weak viewModel] in viewModel?.discardStoreStockEdits() })
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
