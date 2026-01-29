import SwiftUI

struct POSRefundItemsSelectionView: View {
    let onClose: () -> Void
    let onContinue: () -> Void

    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.posModalParentSize) private var parentSize

    private var refundSelectableItems: [POSRefundSelectableItem] {
        orderListModel.ordersController.refundSelectableItems
    }

    private var selectedItems: [POSRefundSelectableItem] {
        refundSelectableItems.filter { $0.isSelected }
    }

    private var hasSelectedItems: Bool {
        refundSelectableItems.contains { $0.isSelected }
    }

    private var allItemsSelected: Bool {
        !refundSelectableItems.isEmpty &&
        refundSelectableItems.allSatisfy { $0.isSelected }
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            itemsHeaderView

            Divider()
                .overlay(Color.posOutlineVariant.opacity(0.5))

            itemsList

            continueButton
        }
        .padding(POSPadding.xLarge)
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding * 2))
    }
}

// MARK: - Subviews

private extension POSRefundItemsSelectionView {
    var headerView: some View {
        HStack {
            Text(Localization.title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .lineLimit(1)
            Spacer()
            Button {
                onClose()
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(.bottom, POSPadding.xLarge)
    }

    var itemsHeaderView: some View {
        HStack(spacing: POSSpacing.small) {
            POSCheckbox(
                isSelected: allItemsSelected,
                onToggle: {
                    orderListModel.ordersController.toggleAllRefundItemsSelection()
                }
            )
            .accessibilityLabel(Localization.selectAllAccessibilityLabel)

            HStack(spacing: POSSpacing.xSmall) {
                Text(Localization.itemsHeaderTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.posOnSurface)
                    .textCase(.uppercase)

                Text(String(format: Localization.itemsSelectedCountFormat, selectedItems.count))
                    .font(.caption.weight(.regular))
                    .foregroundColor(.posOnSurfaceVariantLowest)
                    .textCase(.uppercase)
            }

            Spacer()
        }
        .padding(.bottom, POSPadding.medium)
    }

    var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: POSSpacing.none) {
                ForEach(refundSelectableItems.indices, id: \.self) { index in
                    let item = refundSelectableItems[index]

                    POSRefundItemRow(
                        item: item,
                        onToggle: {
                            orderListModel.ordersController.toggleRefundItemSelection(at: index)
                        }
                    )

                    if index < refundSelectableItems.count - 1 {
                        Divider()
                            .overlay(Color.posOutlineVariant.opacity(0.5))
                    }
                }
            }
        }
    }

    var continueButton: some View {
        Button(Localization.continueButton) {
            onContinue()
        }
        .buttonStyle(POSFilledButtonStyle(size: .normal))
        .disabled(!hasSelectedItems)
        .padding(.top, POSPadding.medium)
    }
}

// MARK: - Localization

private extension POSRefundItemsSelectionView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.refundItemsSelectionView.title",
            value: "Select items to refund",
            comment: "This text appears as the title of a modal screen in the Point of Sale module where users can select specific items from an order to process a refund."
        )

        static let continueButton = NSLocalizedString(
            "pos.refundItemsSelectionView.continueButton",
            value: "Continue",
            comment: "Button label in the Point of Sale refund items selection modal that allows users to proceed to the next step after selecting which items they want to refund from an order."
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundItemsSelectionView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for the close button in the refund items selection modal screen within the Point of Sale system. This text is read by screen readers to help visually impaired users understand that the button will close the modal without processing any refunds."
        )

        static let itemsHeaderTitle = NSLocalizedString(
            "pos.refundItemsSelectionView.itemsHeaderTitle",
            value: "Select all items",
            comment: "A header label that appears at the top of the items list in a Point of Sale refund selection modal, where users can choose which items to refund from an order."
        )

        static let itemsSelectedCountFormat = NSLocalizedString(
            "pos.refundItemsSelectionView.itemsSelectedCountFormat",
            value: "(%d selected)",
            comment: "Label showing number of selected items in the refund items selection modal"
        )

        static let selectAllAccessibilityLabel = NSLocalizedString(
            "pos.refundItemsSelectionView.selectAll.accessibilityLabel",
            value: "Select or deselect all items",
            comment: "This is an accessibility label for a checkbox that allows users to select or deselect all items at once in the refund items selection screen of a point-of-sale system. The text is read by screen readers to help visually impaired users understand the purpose of the select-all toggle control."
        )
    }
}

#if DEBUG
#Preview("POSRefundItemsSelectionView") {
    POSRefundItemsSelectionView(
        onClose: { },
        onContinue: { }
    )
    .environment(POSPreviewHelpers.makePreviewOrdersModel(state: POSPreviewHelpers.loadedState()))
}
#endif
