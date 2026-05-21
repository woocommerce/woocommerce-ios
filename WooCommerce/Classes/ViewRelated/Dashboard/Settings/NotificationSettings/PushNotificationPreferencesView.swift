import SwiftUI

/// Settings screen showing per-site Woo-driven push notification preferences:
/// new orders, new reviews and stock alerts.
///
struct PushNotificationPreferencesView: View {

    @Bindable private var viewModel: PushNotificationPreferencesViewModel

    /// Set by the hosting controller after `super.init`. Default is a no-op so
    /// previews work without it.
    var onNewOrderTapped: () -> Void = {}
    /// Set by the hosting controller after `super.init`. Default is a no-op so
    /// previews work without it.
    var onNewReviewTapped: () -> Void = {}
    /// Set by the hosting controller after `super.init`. Default is a no-op so
    /// previews work without it.
    var onNewStockTapped: () -> Void = {}

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
                    detail: viewModel.isStoreOrderEnabled ? viewModel.storeOrderDetailText : Localization.off,
                    accessibilityHint: Localization.newOrdersAccessibilityHint,
                    action: onNewOrderTapped)
                row(title: Localization.newReviewsTitle,
                    detail: viewModel.isStoreReviewEnabled ? viewModel.storeReviewDetailText : Localization.off,
                    accessibilityHint: Localization.newReviewsAccessibilityHint,
                    action: onNewReviewTapped)
                row(title: Localization.stockTitle,
                    detail: viewModel.isStoreStockEnabled ? viewModel.storeStockDetailText : Localization.off,
                    accessibilityHint: Localization.stockAccessibilityHint,
                    action: onNewStockTapped)
            }
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
        static let newReviewsAccessibilityHint = NSLocalizedString(
            "pushNotificationPreferencesView.newReviews.accessibilityHint",
            value: "Customize new review notifications",
            comment: "VoiceOver hint announced when focused on the New reviews row, describing that it opens a detail screen."
        )
        static let stockTitle = NSLocalizedString(
            "pushNotificationPreferencesView.stock.title",
            value: "Stock",
            comment: "Title of the row that toggles stock push notifications."
        )
        static let stockAccessibilityHint = NSLocalizedString(
            "pushNotificationPreferencesView.stock.accessibilityHint",
            value: "Customize stock notifications",
            comment: "VoiceOver hint announced when focused on the Stock row, describing that it opens a detail screen."
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
