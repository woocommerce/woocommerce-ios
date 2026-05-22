import SwiftUI

/// Hosts `NewReviewNotificationPreferencesDetailView`. Navigation chrome
/// (Save, back button, discard alert, saving spinner) is inherited from
/// `NotificationDetailHostingController`.
///
final class NewReviewNotificationPreferencesHostingController:
    NotificationDetailHostingController<NewReviewNotificationPreferencesDetailView> {

    init(viewModel: PushNotificationPreferencesViewModel) {
        super.init(viewModel: viewModel,
                   rootView: NewReviewNotificationPreferencesDetailView(viewModel: viewModel),
                   onDiscard: { [weak viewModel] in viewModel?.discardStoreReviewEdits() })
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
