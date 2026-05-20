import SwiftUI

/// Detail screen for the New orders push notification preferences. Reached by
/// tapping the New orders row in `PushNotificationPreferencesView`. Navigation
/// chrome (title, Save bar button, discard confirmation) lives on the wrapping
/// `NewOrderNotificationPreferencesHostingController`.
///
struct NewOrderNotificationPreferencesDetailView: View {

    private typealias Threshold = PushNotificationPreferencesViewModel.StoreOrderThreshold

    @Bindable private var viewModel: PushNotificationPreferencesViewModel

    @State private var thresholdInput: String

    init(viewModel: PushNotificationPreferencesViewModel) {
        self.viewModel = viewModel
        _thresholdInput = State(initialValue: Threshold.formatInput(viewModel.storeOrderMinAmount))
    }

    var body: some View {
        List {
            masterToggleSection
            customizationSection
        }
        .listStyle(.insetGrouped)
        .background(Color(.listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        // `leftBarButtonItem` set in UIKit doesn't suppress SwiftUI's own back
        // button, so without this both render side-by-side and only the UIKit
        // one routes through the discard handler.
        .navigationBarBackButtonHidden(true)
        .notice($viewModel.errorNotice)
        .onChange(of: viewModel.storeOrderMinAmount) { _, newValue in
            let formatted = Threshold.formatInput(newValue)
            if formatted != thresholdInput {
                thresholdInput = formatted
            }
        }
    }

    private var masterToggleSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Layout.titleDetailSpacing) {
                HStack {
                    Text(Localization.enableTitle)
                        .bodyStyle()
                    Spacer()
                    Toggle("", isOn: Binding(get: { viewModel.isStoreOrderEnabled },
                                             set: { viewModel.setStoreOrderEnabled($0) }))
                        .labelsHidden()
                }
                Text(Localization.enableSubtitle)
                    .foregroundStyle(Color(.secondaryLabel))
                    .captionStyle()
            }
        }
    }

    private var customizationSection: some View {
        Section {
            radioRow(title: Localization.allOrdersTitle,
                     subtitle: Localization.allOrdersSubtitle,
                     isSelected: viewModel.storeOrderMinAmount == nil) {
                viewModel.setStoreOrderMinAmount(nil)
            }
            radioRow(title: Localization.highValueTitle,
                     subtitle: Localization.highValueSubtitle,
                     isSelected: viewModel.storeOrderMinAmount != nil) {
                let restore = viewModel.lastKnownStoreOrderMinAmount
                    ?? PushNotificationPreferencesViewModel.defaultStoreOrderMinAmount
                // Seed the input synchronously so the threshold field doesn't render
                // with empty text for a frame before the VM's `onChange` syncs it.
                thresholdInput = Threshold.formatInput(restore)
                viewModel.setStoreOrderMinAmount(restore)
            }
            if viewModel.storeOrderMinAmount != nil {
                thresholdField
            }
        } header: {
            Text(Localization.customizeHeader)
        }
        .disabled(!viewModel.isStoreOrderEnabled)
        .opacity(viewModel.isStoreOrderEnabled ? 1.0 : Layout.disabledOpacity)
    }

    private func radioRow(title: String,
                          subtitle: String,
                          isSelected: Bool,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Layout.contentSpacing) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color(.tertiaryLabel))
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Layout.titleDetailSpacing) {
                    Text(title)
                        .bodyStyle()
                    Text(subtitle)
                        .foregroundStyle(Color(.secondaryLabel))
                        .captionStyle()
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var thresholdField: some View {
        HStack {
            Text(Localization.thresholdLabel)
                .bodyStyle()
            Spacer()
            TextField(Localization.thresholdPlaceholder, text: $thresholdInput)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
        }
    }
}

private extension NewOrderNotificationPreferencesDetailView {
    enum Layout {
        static let contentSpacing: CGFloat = 12
        static let titleDetailSpacing: CGFloat = 4
        static let disabledOpacity: Double = 0.5
    }

    enum Localization {
        static let title = NSLocalizedString(
            "newOrderNotificationPreferencesDetailView.title",
            value: "New orders",
            comment: "Title of the new-order push notification preferences detail screen."
        )
        static let enableTitle = NSLocalizedString(
            "newOrderNotificationPreferencesDetailView.enable.title",
            value: "Enable notifications",
            comment: "Title of the master toggle for new-order push notifications."
        )
        static let enableSubtitle = NSLocalizedString(
            "newOrderNotificationPreferencesDetailView.enable.subtitle",
            value: "Get notified when an order is placed in your store.",
            comment: "Subtitle of the master toggle for new-order push notifications."
        )
        static let customizeHeader = NSLocalizedString(
            "newOrderNotificationPreferencesDetailView.notifyMeFor.header",
            value: "Notify me for",
            comment: "Section header for new-order notification customization options."
        )
        static let allOrdersTitle = NSLocalizedString(
            "newOrderNotificationPreferencesDetailView.allOrders.title",
            value: "All new orders",
            comment: "Title of the radio row that enables notifications for every new order."
        )
        static let allOrdersSubtitle = NSLocalizedString(
            "newOrderNotificationPreferencesDetailView.allOrders.subtitle",
            value: "Ping for every order, regardless of value.",
            comment: "Subtitle of the radio row that enables notifications for every new order."
        )
        static let highValueTitle = NSLocalizedString(
            "newOrderNotificationPreferencesDetailView.highValue.title",
            value: "Only high-value orders",
            comment: "Title of the radio row that filters notifications to orders above a threshold."
        )
        static let highValueSubtitle = NSLocalizedString(
            "newOrderNotificationPreferencesDetailView.highValue.subtitle",
            value: "Filter to orders above your threshold.",
            comment: "Subtitle of the radio row that filters notifications to orders above a threshold."
        )
        static let thresholdLabel = NSLocalizedString(
            "newOrderNotificationPreferencesDetailView.threshold.label",
            value: "Threshold",
            comment: "Label for the order-total threshold text field."
        )
        static let thresholdPlaceholder = NSLocalizedString(
            "newOrderNotificationPreferencesDetailView.threshold.placeholder",
            value: "Amount",
            comment: "Placeholder for the order-total threshold text field."
        )
    }
}
