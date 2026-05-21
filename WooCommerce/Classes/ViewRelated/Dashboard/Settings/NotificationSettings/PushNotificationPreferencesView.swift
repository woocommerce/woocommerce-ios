import SwiftUI

/// Settings screen showing per-site Woo-driven push notification preferences:
/// new orders, new reviews and stock alerts.
///
struct PushNotificationPreferencesView: View {

    @Bindable private var viewModel: PushNotificationPreferencesViewModel

    init(viewModel: PushNotificationPreferencesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .loading, .loaded:
                preferencesList
                    .disabled(viewModel.loadState == .loading)
            case .error:
                EmptyState(title: Localization.errorTitle,
                           description: Localization.errorMessage,
                           image: .errorImage,
                           buttonTitle: Localization.retry,
                           buttonAction: {
                    Task { await viewModel.load() }
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.loadState == .loading {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
        .task {
            if viewModel.loadState == .loading {
                await viewModel.load()
            }
        }
        .notice($viewModel.errorNotice)
    }

    private var preferencesList: some View {
        List {
            Section {
                row(title: Localization.newOrdersTitle,
                    detail: viewModel.isStoreOrderEnabled ? Localization.newOrdersDetail : Localization.off)
                row(title: Localization.newReviewsTitle,
                    detail: viewModel.isStoreReviewEnabled ? Localization.newReviewsDetail : Localization.off)
                row(title: Localization.stockTitle,
                    detail: viewModel.isStoreStockEnabled ? Localization.stockDetail : Localization.off)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func row(title: String, detail: String) -> some View {
        HStack(spacing: Layout.contentSpacing) {
            VStack(alignment: .leading, spacing: Layout.titleDetailSpacing) {
                Text(title)
                    .bodyStyle()
                Text(detail)
                    .foregroundStyle(Color(.secondaryLabel))
                    .captionStyle()
            }
            Spacer()
            Image(systemName: "chevron.forward")
                .foregroundStyle(Color(.tertiaryLabel))
                .font(.footnote.weight(.semibold))
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private extension PushNotificationPreferencesView {
    enum Layout {
        static let contentSpacing: CGFloat = 8
        static let titleDetailSpacing: CGFloat = 4
    }
}

extension PushNotificationPreferencesView {
    enum Localization {
        static let title = NSLocalizedString(
            "pushNotificationPreferencesView.title",
            value: "Push Notifications",
            comment: "Title of the push notification preferences screen."
        )
        static let newOrdersTitle = NSLocalizedString(
            "pushNotificationPreferencesView.newOrders.title",
            value: "New orders",
            comment: "Title of the row that toggles new-order push notifications."
        )
        static let newOrdersDetail = NSLocalizedString(
            "pushNotificationPreferencesView.newOrders.detail",
            value: "All orders",
            comment: "Detail text for the row that toggles new-order push notifications."
        )
        static let newReviewsTitle = NSLocalizedString(
            "pushNotificationPreferencesView.newReviews.title",
            value: "New reviews",
            comment: "Title of the row that toggles new-review push notifications."
        )
        static let newReviewsDetail = NSLocalizedString(
            "pushNotificationPreferencesView.newReviews.detail",
            value: "All reviews",
            comment: "Detail text for the row that toggles new-review push notifications."
        )
        static let stockTitle = NSLocalizedString(
            "pushNotificationPreferencesView.stock.title",
            value: "Stock",
            comment: "Title of the row that toggles stock push notifications."
        )
        static let stockDetail = NSLocalizedString(
            "pushNotificationPreferencesView.stock.detail",
            value: "All stock alerts",
            comment: "Detail text for the row that toggles stock push notifications."
        )
        static let off = NSLocalizedString(
            "pushNotificationPreferencesView.off",
            value: "Off",
            comment: "Detail text shown on a notification row when notifications are disabled."
        )
        static let errorTitle = NSLocalizedString(
            "pushNotificationPreferencesView.error.title",
            value: "Couldn't load notification preferences",
            comment: "Title shown when the push notification preferences fail to load."
        )
        static let errorMessage = NSLocalizedString(
            "pushNotificationPreferencesView.error.message",
            value: "Please check your connection and try again.",
            comment: "Message shown when the push notification preferences fail to load."
        )
        static let retry = NSLocalizedString(
            "pushNotificationPreferencesView.retry",
            value: "Retry",
            comment: "Button on the error state to retry loading push notification preferences."
        )
    }
}
