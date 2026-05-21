import SwiftUI

/// Settings screen showing per-site Woo-driven push notification preferences:
/// new orders, new reviews and stock alerts.
///
struct PushNotificationPreferencesView: View {

    @Bindable private var viewModel: PushNotificationPreferencesViewModel

    /// Set by the hosting controller after `super.init`. Default is a no-op so
    /// previews work without it.
    var onNewOrderTapped: () -> Void = {}

    init(viewModel: PushNotificationPreferencesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            switch viewModel.notificationsEnabled {
            case .none:
                ProgressView().progressViewStyle(.circular)
            case .some(false):
                notificationsDisabledView
            case .some(true):
                preferencesContent
            }
        }
        .background(Color(.listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.notificationsEnabled == true && viewModel.loadState == .loading {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
        .task {
            await viewModel.checkNotificationPermission()
            if viewModel.loadState == .loading {
                await viewModel.load()
            }
        }
        .notice($viewModel.errorNotice)
    }

    @ViewBuilder
    private var preferencesContent: some View {
        switch viewModel.loadState {
        case .loading, .loaded:
            preferencesList
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

    private var notificationsDisabledView: some View {
        VStack(spacing: Layout.emptyStateContentSpacing) {
            Spacer()

            Image(uiImage: .bellIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.emptyStateImageWidth)

            Text(Localization.notificationsDisabled)

            Button(Localization.enableNotificationsCTA) {
                Task { await openSettingsApp() }
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()
        }
        .scrollVerticallyIfNeeded()
        .padding(.horizontal)
    }

    private func openSettingsApp() async {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        await UIApplication.shared.open(url)
    }

    private var preferencesList: some View {
        List {
            Section {
                HStack {
                    Text(Localization.notificationsEnabled)
                    Spacer()
                    Button(Localization.settingsAppCTA) {
                        Task { await openSettingsApp() }
                    }
                }
            } footer: {
                Text(Localization.notificationsFooter)
            }

            Section {
                row(title: Localization.newOrdersTitle,
                    detail: viewModel.isStoreOrderEnabled ? viewModel.storeOrderDetailText : Localization.off,
                    accessibilityHint: Localization.newOrdersAccessibilityHint,
                    action: onNewOrderTapped)
                row(title: Localization.newReviewsTitle,
                    detail: viewModel.isStoreReviewEnabled ? Localization.newReviewsDetail : Localization.off)
                row(title: Localization.stockTitle,
                    detail: viewModel.isStoreStockEnabled ? Localization.stockDetail : Localization.off)
            }
            .disabled(viewModel.loadState == .loading)
        }
        .listStyle(.insetGrouped)
    }

    /// Title + detail + chevron. Tappable when `action` is non-nil. Uses
    /// `onTapGesture` rather than `Button` to avoid List's interactive-row tint.
    private func row(title: String,
                     detail: String,
                     accessibilityHint: String? = nil,
                     action: (() -> Void)? = nil) -> some View {
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
        .onTapGesture { action?() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .ifLet(accessibilityHint) { view, hint in
            view.accessibilityHint(hint)
        }
    }
}

private extension View {
    /// Applies `transform` only when `value` is non-nil.
    @ViewBuilder
    func ifLet<T, Transform: View>(_ value: T?,
                                   transform: (Self, T) -> Transform) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}

private extension PushNotificationPreferencesView {
    enum Layout {
        static let contentSpacing: CGFloat = 8
        static let titleDetailSpacing: CGFloat = 4
        static let emptyStateContentSpacing: CGFloat = 16
        static let emptyStateImageWidth: CGFloat = 120
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
        static let newOrdersAccessibilityHint = NSLocalizedString(
            "pushNotificationPreferencesView.newOrders.accessibilityHint",
            value: "Customize new order notifications",
            comment: "VoiceOver hint announced when focused on the New orders row, describing that it opens a detail screen."
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
        static let notificationsEnabled = NSLocalizedString(
            "pushNotificationPreferencesView.notificationsEnabled",
            value: "Notifications enabled",
            comment: "Label indicating notifications are enabled, shown at the top of the push notification preferences screen."
        )
        static let settingsAppCTA = NSLocalizedString(
            "pushNotificationPreferencesView.settingsAppCTA",
            value: "Change",
            comment: "Button on the push notification preferences screen that opens the app's notification settings in the iOS Settings app."
        )
        static let notificationsFooter = NSLocalizedString(
            "pushNotificationPreferencesView.notificationsFooter",
            value: "Including reminders and remote push notifications.",
            comment: "Footer of the notifications-enabled section on the push notification preferences screen."
        )
        static let notificationsDisabled = NSLocalizedString(
            "pushNotificationPreferencesView.notificationsDisabled",
            value: "Notifications are disabled for Woo",
            comment: "Empty state title shown on the push notification preferences screen when iOS notifications are disabled for Woo."
        )
        static let enableNotificationsCTA = NSLocalizedString(
            "pushNotificationPreferencesView.enableNotificationsCTA",
            value: "Enable notifications",
            comment: "Primary button on the push notification preferences empty state that opens the iOS Settings app to enable notifications."
        )
    }
}
