import SwiftUI

/// Hosts `NewReviewNotificationPreferencesDetailView`.
final class NewReviewNotificationPreferencesHostingController:
    NotificationDetailHostingController<NewReviewNotificationPreferencesDetailView> {

    init(viewModel: PushNotificationPreferencesViewModel) {
        super.init(viewModel: viewModel,
                   rootView: NewReviewNotificationPreferencesDetailView(viewModel: viewModel),
                   notificationType: .newReview,
                   onDiscard: { [weak viewModel] in viewModel?.discardStoreReviewEdits() })
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
