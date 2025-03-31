import SwiftUI
import Yosemite

struct WooShippingSplitShipmentsDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: WooShippingSplitShipmentsViewModel

    @State private var showingMergeAllSheet = false
    @State private var showingRemovalSheet = false

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.shipments.count > 1 {
                    VStack(spacing: 0) {
                        topTabView
                        Divider()
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: Layout.contentPadding) {
                        AdaptiveStack(horizontalAlignment: .leading) {
                            Text(viewModel.itemsCountLabel)
                                .headlineStyle()
                            Spacer()
                            Text(viewModel.itemsDetailLabel)
                                .foregroundStyle(Color(.textSubtle))
                        }

                        VStack(spacing: Layout.verticalSpacing) {
                            ForEach(viewModel.currentShipment) { item in
                                CollapsibleShipmentItemCard(viewModel: item)
                            }
                        }
                    }
                    .padding(Layout.contentPadding)
                }

                Spacer()

                noticeStack
                    .padding(Layout.contentPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.selectAll) {
                        viewModel.selectAll()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.done) {
                        dismiss()
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
    }
}

private extension WooShippingSplitShipmentsDetailView {
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
                       tabsIconSize: nil,
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
            ForEach(viewModel.topTabItems, id: \.name) { tab in
                Button(String.localizedStringWithFormat(Localization.removeShipmentFormat, tab.name.lowercased())) {
                    // TODO
                }
            }
            Divider()
            Button(Localization.mergeAll) {
                showingMergeAllSheet = true
            }
        } label: {
            Image(systemName: "ellipsis")
                .padding()
        }
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
        ScrollableVStack(alignment: .leading, spacing: Layout.contentPadding) {
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
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(Localization.cancel) {
                showingMergeAllSheet = false
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .presentationDetents([.fraction(0.4), .medium, .large])
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
        .padding(WooShippingSplitShipmentsDetailView.Layout.contentPadding)
        .background {
            RoundedRectangle(cornerRadius: WooShippingSplitShipmentsDetailView.Layout.cornerRadius)
                .fill(Color(.text))
                .shadow(color: Color(.text).opacity(shadowColorOpacity),
                        radius: WooShippingSplitShipmentsDetailView.Layout.shadowRadius,
                        y: WooShippingSplitShipmentsDetailView.Layout.shadowYOffset)
        }
    }
}

fileprivate extension WooShippingSplitShipmentsDetailView {
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
    }
}

#if DEBUG
#Preview {
    WooShippingSplitShipmentsDetailView(viewModel: WooShippingSplitShipmentsViewModel(order: ShippingLabelSampleData.sampleOrder(),
                                                                                      config: ShippingLabelSampleData.sampleWooShippingConfig(),
                                                                                      items: [ShippingLabelPackageItem(productOrVariationID: 1,
                                                                                                                       name: "Shirt",
                                                                                                                       weight: 0.5,
                                                                                                                       quantity: 2,
                                                                                                                       value: 9.99,
                                                                                                                       dimensions: ProductDimensions(length: "",
                                                                                                                                                     width: "",
                                                                                                                                                     height: ""),
                                                                                                                       attributes: [],
                                                                                                                       imageURL: nil)]))
}
#endif
