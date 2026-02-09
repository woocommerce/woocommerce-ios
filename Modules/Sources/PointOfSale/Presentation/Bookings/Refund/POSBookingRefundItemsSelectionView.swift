// POSBookingRefundItemsSelectionView.swift
import SwiftUI

/// Item selection view for booking refunds.
///
/// Reads selectable items from `POSBookingRefundController` instead of `POSOrderListModel`,
/// reusing the same UI pattern as `POSRefundItemsSelectionView`.
struct POSBookingRefundItemsSelectionView: View {
    let refundController: POSBookingRefundController
    let onClose: () -> Void
    let onContinue: () -> Void

    @Environment(\.posModalParentSize) private var parentSize

    private var refundSelectableItems: [POSRefundSelectableItem] {
        refundController.refundSelectableItems
    }

    private var selectedItems: [POSRefundSelectableItem] {
        refundSelectableItems.filter(\.isSelected)
    }

    private var hasSelectedItems: Bool {
        refundSelectableItems.contains(where: \.isSelected)
    }

    private var allItemsSelected: Bool {
        !refundSelectableItems.isEmpty &&
        refundSelectableItems.allSatisfy(\.isSelected)
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

private extension POSBookingRefundItemsSelectionView {
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
                    refundController.toggleAllRefundItemsSelection()
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
                            refundController.toggleRefundItemSelection(at: index)
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

private extension POSBookingRefundItemsSelectionView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.bookingRefundItemsSelectionView.title",
            value: "Select items to refund",
            comment: "Title for the booking refund items selection modal"
        )

        static let continueButton = NSLocalizedString(
            "pos.bookingRefundItemsSelectionView.continueButton",
            value: "Continue",
            comment: "Button to continue with selected items for booking refund"
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.bookingRefundItemsSelectionView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on booking refund items selection modal"
        )

        static let itemsHeaderTitle = NSLocalizedString(
            "pos.bookingRefundItemsSelectionView.itemsHeaderTitle",
            value: "Select all items",
            comment: "Header label for items in the booking refund items selection modal"
        )

        static let itemsSelectedCountFormat = NSLocalizedString(
            "pos.bookingRefundItemsSelectionView.itemsSelectedCountFormat",
            value: "(%d selected)",
            comment: "Label showing number of selected items in the booking refund items selection modal"
        )

        static let selectAllAccessibilityLabel = NSLocalizedString(
            "pos.bookingRefundItemsSelectionView.selectAll.accessibilityLabel",
            value: "Select or deselect all items",
            comment: "Accessibility label for the select-all checkbox in the booking refund items selection modal"
        )
    }
}
