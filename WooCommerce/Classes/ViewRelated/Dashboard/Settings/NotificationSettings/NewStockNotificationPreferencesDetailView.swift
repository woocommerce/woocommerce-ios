import SwiftUI

/// Detail screen for the Stock push notification preferences. Reached by
/// tapping the Stock row in `PushNotificationPreferencesView`. Navigation
/// chrome (title, Save bar button, discard confirmation) lives on the wrapping
/// `NewStockNotificationPreferencesHostingController`.
///
struct NewStockNotificationPreferencesDetailView: View {

    @Bindable private var viewModel: PushNotificationPreferencesViewModel

    init(viewModel: PushNotificationPreferencesViewModel) {
        self.viewModel = viewModel
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
            toggleRow(title: Localization.lowStockTitle,
                      subtitle: Localization.lowStockSubtitle,
                      isOn: Binding(get: { viewModel.isStoreStockLowStock },
                                    set: { viewModel.setStoreStockLowStock($0) }))
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
    enum Layout {
        static let titleDetailSpacing: CGFloat = 4
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
