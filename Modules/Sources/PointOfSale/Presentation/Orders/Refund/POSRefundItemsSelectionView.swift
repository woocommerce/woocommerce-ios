import SwiftUI

struct POSRefundItemsSelectionView: View {
    @Binding var isPresented: Bool
    @Environment(POSOrderListModel.self) private var orderListModel
    let onContinue: ([POSRefundSelectableItem]) -> Void

    private var refundSelectableItems: [POSRefundSelectableItem] {
        orderListModel.ordersController.refundSelectableItems
    }

    private var selectedItems: [POSRefundSelectableItem] {
        refundSelectableItems.filter { $0.isSelected }
    }

    private var hasSelectedItems: Bool {
        refundSelectableItems.contains { $0.isSelected }
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView

            Divider()
                .overlay(Color.posOutlineVariant.opacity(0.5))

            itemsList

            Divider()
                .overlay(Color.posOutlineVariant.opacity(0.5))

            continueButton
        }
        .padding(POSPadding.xxLarge)
        .background(Color.posSurfaceBright)
        .frame(width: Constants.modalWidth)
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
                isPresented = false
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(.bottom, POSPadding.medium)
    }

    var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: POSSpacing.none) {
                ForEach(Array(refundSelectableItems.enumerated()), id: \.element.id) { index, item in
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
        .padding(.vertical, POSPadding.medium)
    }

    var continueButton: some View {
        Button(Localization.continueButton) {
            onContinue(selectedItems)
        }
        .buttonStyle(POSFilledButtonStyle(size: .normal))
        .disabled(!hasSelectedItems)
        .padding(.top, POSPadding.medium)
    }
}

// MARK: - Constants

private extension POSRefundItemsSelectionView {
    enum Constants {
        static let modalWidth: CGFloat = 560
    }
}

// MARK: - Localization

private extension POSRefundItemsSelectionView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.refundItemsSelectionView.title",
            value: "Select items to refund",
            comment: "Title for the refund items selection modal"
        )

        static let continueButton = NSLocalizedString(
            "pos.refundItemsSelectionView.continueButton",
            value: "Continue",
            comment: "Button to continue with selected items for refund"
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundItemsSelectionView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on refund items selection modal"
        )
    }
}

#if DEBUG
#Preview("POSRefundItemsSelectionView") {
    POSRefundItemsSelectionView(
        isPresented: .constant(true),
        onContinue: { _ in }
    )
    .environment(POSPreviewHelpers.makePreviewOrdersModel(state: POSPreviewHelpers.loadedState()))
}
#endif
