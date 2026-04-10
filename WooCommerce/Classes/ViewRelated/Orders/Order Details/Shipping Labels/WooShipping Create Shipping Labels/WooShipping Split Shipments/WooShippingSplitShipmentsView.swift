import SwiftUI
import Yosemite
import struct WooFoundation.ScrollableVStack

struct WooShippingSplitShipmentsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory

    @ObservedObject var viewModel: ViewModel

    var onShipmentUpdate: ([Shipment]) -> Void

    @State private var showingMergeAllSheet = false

    @State private var shipmentToRemove: ViewModel.Shipment?
    @State private var shipmentToMergeInto: ViewModel.Shipment?

    typealias ViewModel = WooShippingSplitShipmentsViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.shipments.count > 1 {
                    VStack(spacing: 0) {
                        topTabView
                        Divider()
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: Layout.contentPadding) {
                        if viewModel.currentShipment.isPurchased {
                            fulfilledShipmentView
                        }

                        AdaptiveStack(horizontalAlignment: .leading) {
                            Text(viewModel.itemsCountLabel)
                                .headlineStyle()
                            Spacer()
                            Text(viewModel.itemsDetailLabel)
                                .foregroundStyle(Color(.textSubtle))
                        }

                        VStack(spacing: Layout.verticalSpacing) {
                            ForEach(viewModel.currentShipment.contents) { item in
                                CollapsibleShipmentItemCard(viewModel: item)
                            }
                        }

                        if sizeCategory.isAccessibilityCategory {
                            Spacer()
                            noticeStack
                        }
                    }
                    .padding(Layout.contentPadding)
                }

                if !sizeCategory.isAccessibilityCategory {
                    Spacer()
                    noticeStack
                        .padding(Layout.contentPadding)
                }
            }
            .disabled(viewModel.isSavingShipmentInfo)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.selectAll) {
                        viewModel.selectAll()
                    }
                    .disabled(
                        viewModel.isSelectAllItemsDisabled
                    )
                }

                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSavingShipmentInfo {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    } else {
                        Button(Localization.done) {
                            guard viewModel.containsUnsavedChanges else {
                                dismiss()
                                return
                            }

                            saveShipmentInfoAndDismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(isPresented: $showingMergeAllSheet) {
            mergeAllUnfulfilledSheet
        }
        .sheet(item: $shipmentToRemove) { shipment in
            removeShipmentSheet(for: shipment)
        }
        .alert(
            Localization.SaveShipmentError.title,
            isPresented: $viewModel.shouldShowSaveShipmentErrorAlert
        ) {
            Button(Localization.SaveShipmentError.cancel, role: .cancel) {
                // User chose to cancel, do nothing
            }
            Button(Localization.SaveShipmentError.retry) {
                saveShipmentInfoAndDismiss()
            }
            Button(Localization.SaveShipmentError.revertChanges) {
                viewModel.revertChanges()
            }
        }
    }
}

private extension WooShippingSplitShipmentsView {
    var topTabView: some View {
        HStack(spacing: 0) {
            TopTabView(tabs: viewModel.topTabItems,
                       showContent: false,
                       showDividerBelowTabs: false,
                       selectedTabIndex: $viewModel.selectedShipmentIndex,
                       tabsContainerHorizontalPadding: nil,
                       selectedStateColor: .accentColor,
                       unselectedStateColor: .secondary,
                       selectedTabIndicatorHeight: Layout.selectedTabIndicatorHeight,
                       tabPadding: Layout.tabPadding,
                       tabsNameFont: Font.subheadline.bold(),
                       tabsIconSize: Layout.purchasedIconWidth,
                       tabsIconAlignment: .trailing,
                       tabsIconForegroundColor: Layout.green,
                       tabItemContentHorizontalPadding: Layout.tabItemContentHorizontalPadding,
                       tabItemContentVerticalPadding: Layout.tabItemContentVerticalPadding)
            .overlay(alignment: .trailing) {
                LinearGradient(gradient: Gradient(colors: [.clear, Color(.basicBackground)]), startPoint: .leading, endPoint: .center)
                    .frame(width: Layout.gradientViewWidth)
                    .renderedIf(viewModel.selectedShipmentIndex < viewModel.topTabItems.count - 1)
            }

            removeShipmentMenu
        }
    }

    var removeShipmentMenu: some View {
        Menu {
            ForEach(viewModel.removableShipments) { shipment in
                Button(
                    String.localizedStringWithFormat(
                        Localization.removeShipmentFormat,
                        viewModel.retrieveName(for: shipment).lowercased()
                    )
                ) {
                    shipmentToRemove = shipment
                }
            }

            Divider()

            Button(Localization.mergeAll) {
                showingMergeAllSheet = true
            }
            .renderedIf(viewModel.isMergeAllUnfulfilledAvailable())
        } label: {
            Image(systemName: "ellipsis")
                .padding()
        }
        .renderedIf(viewModel.shouldShowRemoveShipmentMenu)
    }

    var fulfilledShipmentView: some View {
        VStack {
            Text(Localization.PurchasedShipment.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(Localization.PurchasedShipment.subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .multilineTextAlignment(.leading)
        .foregroundStyle(Layout.green)
        .padding(Layout.contentPadding)
        .background(
            Layout.greenBackground
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        )
    }

    var noticeStack: some View {
        VStack(spacing: Layout.contentPadding) {
            if let message = viewModel.instructions {
                MessageSnackBar(message: message, verticalAlignment: .top, icon: {
                    EmptyView()
                }, actionHandler: {
                    viewModel.dismissInstructions()
                })
            }

            if let completionMessage = viewModel.movingCompletionMessage {
                MessageSnackBar(message: completionMessage, actionTitle: Localization.undo, icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Color(.withColorStudio(.green, shade: .shade20)))
                }, actionHandler: {
                    viewModel.undoMovingItems()
                })
            }

            if let moveTo = viewModel.moveToNoticeViewModel {
                MoveToShipmentNotice(viewModel: moveTo, onMoving: { destination in
                    viewModel.moveSelectedItems(to: destination)
                })
            }
        }
    }

    var mergeAllUnfulfilledSheet: some View {
        ScrollableVStack(alignment: .leading,
                         padding: Layout.contentPadding,
                         spacing: Layout.verticalSpacing) {
            Text(Localization.MergeAllUnfulfilledSheet.title)
                .font(.title3)
                .bold()
                .multilineTextAlignment(.leading)
                .padding(.top)

            Text(Localization.MergeAllUnfulfilledSheet.description)
                .font(.subheadline)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(Localization.MergeAllUnfulfilledSheet.confirmCTA) {
                viewModel.mergeAllUnfulfilledShipments()
                showingMergeAllSheet = false
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(Localization.cancel) {
                showingMergeAllSheet = false
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .presentationDetents([.fraction(0.4), .medium, .large])
    }

    func removeShipmentSheet(for shipment: ViewModel.Shipment) -> some View {
        ScrollableVStack(padding: Layout.contentPadding,
                         spacing: Layout.contentPadding) {
            VStack(alignment: .leading) {
                Text(Localization.RemoveShipmentSheet.title)
                    .font(.title3)
                    .bold()

                Text(String.localizedStringWithFormat(Localization.RemoveShipmentSheet.subtitle, shipment.quantity))
                    .font(.subheadline)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top)

            VStack {
                ForEach(viewModel.shipmentsToMerge(for: shipment)) { otherShipment in
                    Button {
                        shipmentToMergeInto = otherShipment
                    } label: {
                        HStack {
                            Image(systemName: "arrow.turn.down.right")
                                .foregroundStyle(otherShipment == shipmentToMergeInto ? Color.accentColor : Color.secondary)
                                .font(.subheadline)
                                .bold()
                            VStack(alignment: .leading) {
                                Text(viewModel.retrieveName(for: otherShipment))
                                    .font(.headline)
                                AdaptiveStack(horizontalAlignment: .leading) {
                                    Text(otherShipment.quantity)
                                    Spacer()
                                    Text(otherShipment.itemsDetailLabel)
                                }
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(Layout.contentPadding)
                        .if(otherShipment == shipmentToMergeInto) { view in
                            view.background(
                                Color(.listSelectedBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                            )
                        }
                        .roundedBorder(cornerRadius: Layout.cornerRadius,
                                       lineColor: otherShipment == shipmentToMergeInto ? .accentColor : Color(.separator),
                                       lineWidth: otherShipment == shipmentToMergeInto ? 2 : 1)
                    }
                }
            }

            Spacer()

            VStack {
                Button(String.localizedStringWithFormat(Localization.RemoveShipmentSheet.confirmCTA,
                                                        viewModel.retrieveName(for: shipment))) {
                    guard let shipmentToMergeInto else {
                        return
                    }
                    viewModel.removeShipment(shipment, mergeInto: shipmentToMergeInto)
                    shipmentToRemove = nil
                }
                .buttonStyle(DestructiveButtonStyle())
                .disabled(shipmentToMergeInto == nil)

                Button(Localization.cancel) {
                    shipmentToRemove = nil
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .presentationDetents([.medium, .large])
        .onDisappear {
            shipmentToMergeInto = nil
        }
    }

    /// Saves shipment info and dismisses the view on success
    private func saveShipmentInfoAndDismiss() {
        Task {
            do {
                try await viewModel.saveShipmentInfo()
                onShipmentUpdate(viewModel.shipments)
                dismiss()
            } catch {
                // Error is handled by the ViewModel.
            }
        }
    }
}

private struct MessageSnackBar<IconContent: View>: View {
    let message: AttributedString
    var actionTitle: String?
    var verticalAlignment: VerticalAlignment = .center
    let icon: (() -> IconContent)
    let actionHandler: () -> Void

    private let hSpacing: CGFloat = 8
    private let shadowColorOpacity: CGFloat = 0.16

    var body: some View {
        HStack(alignment: verticalAlignment, spacing: hSpacing) {
            icon()

            Text(message)

            Spacer()

            Button {
                actionHandler()
            } label: {
                if let actionTitle {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundStyle(Color(UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade30),
                                                       dark: .withColorStudio(.wooCommercePurple, shade: .shade40))))
                } else {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color(.withColorStudio(.gray)))
                }
            }
        }
        .padding(WooShippingSplitShipmentsView.Layout.contentPadding)
        .background {
            RoundedRectangle(cornerRadius: WooShippingSplitShipmentsView.Layout.cornerRadius)
                .fill(Color(.text))
                .shadow(color: Color(.text).opacity(shadowColorOpacity),
                        radius: WooShippingSplitShipmentsView.Layout.shadowRadius,
                        y: WooShippingSplitShipmentsView.Layout.shadowYOffset)
        }
    }
}

fileprivate extension WooShippingSplitShipmentsView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let borderCornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 8
        static let shadowYOffset: CGFloat = 2
        static let borderWidth: CGFloat = 0.5
        static let verticalSpacing: CGFloat = 8
        static let selectedTabIndicatorHeight: CGFloat = 3.0
        static let tabPadding: CGFloat = 9.0
        static let tabItemContentHorizontalPadding: CGFloat = 16.0
        static let tabItemContentVerticalPadding: CGFloat = 9.0
        static let cornerRadius: CGFloat = 8
        static let gradientViewWidth: CGFloat = 32
        static let purchasedIconWidth: CGFloat = 16

        static let green = Color(UIColor(light: .withColorStudio(.green, shade: .shade60),
                                         dark: .withColorStudio(.green, shade: .shade40)))
        static let greenBackground = Color.withColorStudio(name: .green, shade: .shade0)
    }

    enum Localization {
        static let title = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.title",
            value: "Split Shipments",
            comment: "Title of the split shipments detail view in the shipping label creation flow"
        )
        static let selectAll = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.selectAll",
            value: "Select All",
            comment: "Button to select all items in the shipment detail in the shipping label creation flow"
        )
        static let done = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.done",
            value: "Done",
            comment: "Button to save split shipment configurations in the shipping label creation flow"
        )
        static let undo = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.undo",
            value: "Undo",
            comment: "Button to revert moving items between shipments in the shipping label creation flow"
        )
        static let cancel = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.cancel",
            value: "Cancel",
            comment: "Button to dismiss a sheet in the shipping label creation flow"
        )
        static let removeShipmentFormat = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.removeShipmentFormat",
            value: "Remove %1$@",
            comment: "Button to remove a shipment in the shipping label creation flow. " +
            "The placeholder is the name of a shipment. Reads as: 'Remove shipment 1'."
        )
        static let mergeAll = NSLocalizedString(
            "wooShippingSplitShipmentsDetailView.mergeAll",
            value: "Merge all unfulfilled",
            comment: "Button to merge all unfulfilled shipments in the shipping label creation flow."
        )

        enum MergeAllUnfulfilledSheet {
            static let title = NSLocalizedString(
                "wooShippingSplitShipmentsDetailView.mergeAllUnfulfilledSheet.title",
                value: "Merge all unfulfilled shipments",
                comment: "Title of the merge all unfulfilled shipments sheet in the shipping label creation flow."
            )
            static let description = NSLocalizedString(
                "wooShippingSplitShipmentsDetailView.mergeAllUnfulfilledSheet.description",
                value: "This will remove all unfulfilled split shipments and move all items into one shipment",
                comment: "Message on the merge all unfulfilled shipments sheet in the shipping label creation flow."
            )
            static let confirmCTA = NSLocalizedString(
                "wooShippingSplitShipmentsDetailView.mergeAllUnfulfilledSheet.confirmCTA",
                value: "Merge all shipments",
                comment: "Button to confirm merging all unfulfilled shipments sheet in the shipping label creation flow."
            )
        }

        enum RemoveShipmentSheet {
            static let title = NSLocalizedString(
                "wooShippingSplitShipmentsDetailView.removeShipmentSheet.title",
                value: "Remove shipment",
                comment: "Title of the sheet to confirm removing a shipment in the shipping label creation flow."
            )
            static let subtitle = NSLocalizedString(
                "wooShippingSplitShipmentsDetailView.removeShipmentSheet.subtitle",
                value: "Choose where to move the %1$@ in this shipment to.",
                comment: "Subtitle of the sheet to confirm removing a shipment in the shipping label creation flow. " +
                "Placeholder is the number of items in the shipment. " +
                "Reads as: 'Choose where to move the 3 items in this shipment to.'"
            )
            static let confirmCTA = NSLocalizedString(
                "wooShippingSplitShipmentsDetailView.removeShipmentSheet.confirmCTA",
                value: "Remove %1$@",
                comment: "Button to confirm removing a shipment in the shipping label creation flow. " +
                "Placeholder is the name of the shipment. " +
                "Reads as: 'Remove Shipment 1.'"
            )
        }

        enum PurchasedShipment {
            static let title = NSLocalizedString(
                "wooShippingSplitShipmentsDetailView.purchasedShipment.title",
                value: "You purchased a label for this shipment.",
                comment: "Title label displayed on a shipment whose label is purchased in the shipping label creation flow."
            )
            static let subtitle = NSLocalizedString(
                "wooShippingSplitShipmentsDetailView.purchasedShipment.subtitle",
                value: "You can't move products into or out of it.",
                comment: "Subtitle label displayed on a shipment whose label is purchased in the shipping label creation flow."
            )
        }

        enum SaveShipmentError {
            static let title = NSLocalizedString(
                "wooShipping.createLabels.splitShipment.saveShipmentError.title",
                value: "Unable to save changes. Please try again.",
                comment: "Title of the error alert when saving split shipment changes fails"
            )
            static let retry = NSLocalizedString(
                "wooShipping.createLabels.splitShipment.saveShipmentError.retry",
                value: "Retry",
                comment: "Retry button title on the error alert when saving split shipment changes fails"
            )
            static let cancel = NSLocalizedString(
                "wooShipping.createLabels.splitShipment.saveShipmentError.cancel",
                value: "Cancel",
                comment: "Cancel button title on the error alert when saving split shipment changes fails"
            )
            static let revertChanges = NSLocalizedString(
                "wooShipping.createLabels.splitShipment.saveShipmentError.revertChanges",
                value: "Revert changes",
                comment: "Button on the error alert to revert changes when saving split shipment changes fails"
            )
        }
    }
}

#if DEBUG
#Preview {
    WooShippingSplitShipmentsView(viewModel: WooShippingSplitShipmentsViewModel(
        order: ShippingLabelSampleData.sampleOrder(),
        remoteShipments: [],
        items: [ShippingLabelPackageItem(productOrVariationID: 1,
                                         orderItemID: 12,
                                         name: "Shirt",
                                         weight: 0.5,
                                         quantity: 2,
                                         value: 9.99,
                                         dimensions: ProductDimensions(length: "",
                                                                       width: "",
                                                                       height: ""),
                                         attributes: [],
                                         imageURL: nil)]),
                                  onShipmentUpdate: { _ in }
    )
}
#endif
