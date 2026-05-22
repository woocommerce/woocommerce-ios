import SwiftUI

/// Detail screen for the Stock push notification preferences. Reached by
/// tapping the Stock row in `PushNotificationPreferencesView`. Navigation
/// chrome (title, Save bar button, discard confirmation) lives on the wrapping
/// `NewStockNotificationPreferencesHostingController`.
///
struct NewStockNotificationPreferencesDetailView: View {

    @Bindable private var viewModel: PushNotificationPreferencesViewModel
    @Bindable private var detailViewModel: NewStockNotificationPreferencesDetailViewModel

    init(viewModel: PushNotificationPreferencesViewModel,
         detailViewModel: NewStockNotificationPreferencesDetailViewModel) {
        self.viewModel = viewModel
        self.detailViewModel = detailViewModel
    }

    var body: some View {
        List {
            masterToggleSection
            customizationSection
        }
        .listStyle(.insetGrouped)
        .background(Color(.listBackground))
        .disabled(viewModel.isSaving)
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        // `leftBarButtonItem` set in UIKit doesn't suppress SwiftUI's own back
        // button, so without this both render side-by-side and only the UIKit
        // one routes through the discard handler.
        .navigationBarBackButtonHidden(true)
        .notice($viewModel.errorNotice)
        .onAppear {
            viewModel.detailDidAppear(notificationType: .stockAlert)
        }
        .task { await detailViewModel.onAppear() }
    }

    private var masterToggleSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Layout.titleDetailSpacing) {
                Toggle(Localization.enableTitle,
                       isOn: Binding(get: { viewModel.isStoreStockEnabled },
                                     set: { viewModel.setStoreStockEnabled($0) }))
                Text(Localization.enableSubtitle)
                    .foregroundStyle(Color(.secondaryLabel))
                    .captionStyle()
            }
        }
    }

    private var customizationSection: some View {
        Section {
            lowStockRow
            toggleRow(title: Localization.outOfStockTitle,
                      subtitle: Localization.outOfStockSubtitle,
                      isOn: Binding(get: { viewModel.isStoreStockOutOfStock },
                                    set: { viewModel.setStoreStockOutOfStock($0) }))
            toggleRow(title: Localization.onBackorderTitle,
                      subtitle: Localization.onBackorderSubtitle,
                      isOn: Binding(get: { viewModel.isStoreStockOnBackorder },
                                    set: { viewModel.setStoreStockOnBackorder($0) }))
        } header: {
            Text(Localization.customizeHeader)
        }
        .disabled(!viewModel.isStoreStockEnabled)
        .opacity(viewModel.isStoreStockEnabled ? 1.0 : Layout.disabledOpacity)
    }

    private var lowStockRow: some View {
        VStack(alignment: .leading, spacing: Layout.titleDetailSpacing) {
            Toggle(Localization.lowStockTitle,
                   isOn: Binding(get: { viewModel.isStoreStockLowStock },
                                 set: { viewModel.setStoreStockLowStock($0) }))
            Text(Localization.lowStockSubtitle)
                .foregroundStyle(Color(.secondaryLabel))
                .captionStyle()
            thresholdLine
                .padding(.top, Layout.thresholdTopSpacing)
        }
    }

    @ViewBuilder
    private var thresholdLine: some View {
        switch detailViewModel.lowStockThresholdState {
        case .loading:
            thresholdLoadingText
        case .value(let number?):
            thresholdValueText(number)
        case .value(nil):
            thresholdUnavailableText
        }
    }

    private func thresholdValueText(_ value: Int) -> some View {
        let valueString = NumberFormatter.localizedString(from: NSNumber(value: value), number: .none)
        let prefix = String.localizedStringWithFormat(Localization.thresholdValuePrefixFormat, valueString)
        var attributed = AttributedString(prefix)
        if let range = attributed.range(of: valueString) {
            attributed[range].font = .caption2.bold()
        }
        var link = AttributedString(Localization.editStoreWideThresholdLink)
        link.link = URL(string: Self.editLinkScheme)
        return (Text(attributed + AttributedString(" ") + link)
                + Text(" ")
                + Text(Image(systemName: Self.externalLinkSymbol)).foregroundColor(.accentColor))
            .font(.caption2)
            .foregroundStyle(Color(.secondaryLabel))
            .environment(\.openURL, OpenURLAction { [detailViewModel] url in
                if url.absoluteString == Self.editLinkScheme {
                    detailViewModel.onTapEditStoreWideThreshold?()
                    return .handled
                }
                return .systemAction
            })
            // Override the auto-generated label so VoiceOver doesn't announce
            // the SF Symbol's name ("arrow up right") at the end of the sentence.
            .accessibilityLabel(prefix + " " + Localization.editStoreWideThresholdLink)
    }

    private var thresholdLoadingText: some View {
        // Render the value-known layout with a placeholder number so the row's
        // vertical space stays stable, and shimmer to signal loading.
        thresholdValueText(Self.loadingPlaceholderValue)
            .redacted(reason: .placeholder)
            .shimmering()
    }

    private var thresholdUnavailableText: some View {
        let prefixString = Localization.thresholdUnavailablePrefix
        let prefix = AttributedString(prefixString)
        var link = AttributedString(Localization.viewStoreWideThresholdLink)
        link.link = URL(string: Self.editLinkScheme)
        let suffix = AttributedString(" " + Localization.thresholdUnavailableSuffix)
        return (Text(prefix + AttributedString(" ") + link)
                + Text(" ")
                + Text(Image(systemName: Self.externalLinkSymbol)).foregroundColor(.accentColor)
                + Text(suffix))
            .font(.caption2)
            .foregroundStyle(Color(.secondaryLabel))
            .environment(\.openURL, OpenURLAction { [detailViewModel] url in
                if url.absoluteString == Self.editLinkScheme {
                    detailViewModel.onTapEditStoreWideThreshold?()
                    return .handled
                }
                return .systemAction
            })
            // Override the auto-generated label so VoiceOver doesn't announce
            // the SF Symbol's name ("arrow up right") between the link and suffix.
            .accessibilityLabel(prefixString + " " + Localization.viewStoreWideThresholdLink + " " + Localization.thresholdUnavailableSuffix)
    }

    private func toggleRow(title: String,
                           subtitle: String,
                           isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: Layout.titleDetailSpacing) {
            Toggle(title, isOn: isOn)
            Text(subtitle)
                .foregroundStyle(Color(.secondaryLabel))
                .captionStyle()
        }
    }
}

private extension NewStockNotificationPreferencesDetailView {
    static let editLinkScheme = "woo-internal://edit-store-wide-threshold"
    static let externalLinkSymbol = "arrow.up.right"
    static let loadingPlaceholderValue = 8

    enum Layout {
        static let titleDetailSpacing: CGFloat = 4
        static let thresholdTopSpacing: CGFloat = 6
        static let disabledOpacity: Double = 0.5
    }

    enum Localization {
        static let title = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.title",
            value: "Stock",
            comment: "Title of the stock push notification preferences detail screen."
        )
        static let enableTitle = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.enable.title",
            value: "Enable stock notifications",
            comment: "Title of the master toggle for stock push notifications."
        )
        static let enableSubtitle = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.enable.subtitle",
            value: "Get notified when product stock changes need your attention.",
            comment: "Subtitle of the master toggle for stock push notifications."
        )
        static let customizeHeader = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.notifyMeFor.header",
            value: "Notify me for",
            comment: "Section header for stock notification customization options."
        )
        static let lowStockTitle = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.lowStock.title",
            value: "Low stock",
            comment: "Title of the toggle row that enables notifications when a product crosses the low-stock threshold."
        )
        static let lowStockSubtitle = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.lowStock.subtitle",
            value: "When a product variant reaches its low stock threshold.",
            comment: "Subtitle of the low-stock toggle row."
        )
        static let thresholdValuePrefixFormat = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.lowStock.thresholdSentenceFormat",
            value: "Products can use their own threshold or the store-wide threshold of\u{00A0}%1$@.",
            comment: "Sentence shown under the Low stock toggle. %1$@ is the store-wide low stock threshold value, e.g. 5. "
                + "The non-breaking space (\\u00A0) before the placeholder keeps the word 'of' and the value on the same line."
        )
        static let thresholdUnavailablePrefix = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.lowStock.thresholdUnavailablePrefix",
            value: "Products can use their own threshold or the store-wide threshold.",
            comment: "Sentence shown under the Low stock toggle when the store-wide threshold value is unavailable."
        )
        static let thresholdUnavailableSuffix = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.lowStock.thresholdUnavailableSuffix",
            value: "to see the current value.",
            comment: "Sentence fragment shown after the 'View store-wide threshold' link when the store-wide threshold value is unavailable."
        )
        static let editStoreWideThresholdLink = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.lowStock.editStoreWideThresholdLink",
            value: "Edit store-wide threshold",
            comment: "Tappable link that opens wp-admin to edit the store-wide low stock threshold."
        )
        static let viewStoreWideThresholdLink = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.lowStock.viewStoreWideThresholdLink",
            value: "View store-wide threshold",
            comment: "Tappable link that opens wp-admin to view the store-wide low stock threshold when its value is unavailable."
        )
        static let outOfStockTitle = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.outOfStock.title",
            value: "Out of stock",
            comment: "Title of the toggle row that enables notifications when a product reaches the no-stock amount."
        )
        static let outOfStockSubtitle = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.outOfStock.subtitle",
            value: "When a product variant hits zero.",
            comment: "Subtitle of the out-of-stock toggle row."
        )
        static let onBackorderTitle = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.onBackorder.title",
            value: "On backorder",
            comment: "Title of the toggle row that enables notifications when a product is backordered."
        )
        static let onBackorderSubtitle = NSLocalizedString(
            "newStockNotificationPreferencesDetailView.onBackorder.subtitle",
            value: "When a customer orders an item that's currently out of stock.",
            comment: "Subtitle of the on-backorder toggle row."
        )
    }
}
