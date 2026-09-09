import SwiftUI
import struct WooFoundation.WooAnalyticsEvent

struct POSRefundItemsSelectionView: View {
    let onClose: () -> Void
    let onContinue: () -> Void
    let onRefreshItems: () -> Void

    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var refundSelectableItems: [POSRefundSelectableItem] {
        orderListModel.ordersController.refundSelectableItems
    }

    private var reviewPreparationState: POSRefundReviewPreparationState {
        orderListModel.ordersController.refundReviewPreparationState
    }

    /// The inline error shown above the continue button: the server's rejection copy when the
    /// preview failed with an actionable code, or the generic copy for other preview failures.
    private var previewErrorMessage: String? {
        guard case .previewError(let message, _) = reviewPreparationState else {
            return nil
        }
        return message ?? Localization.previewError
    }

    /// What the failed preview offers the cashier next. A recognised rejection is deterministic,
    /// so the same request cannot succeed: the way forward is a reloaded item list, or changing
    /// the selection. Only unrecognised failures, network errors among them, keep the retry.
    private var previewRecovery: POSRefundRecovery? {
        guard case .previewError(_, let recovery) = reviewPreparationState else {
            return nil
        }
        return recovery
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

            VStack(spacing: POSSpacing.none) {
                itemsHeaderView

                Divider()
                    .overlay(Color.posOutlineVariant.opacity(0.5))

                itemsList
            }
            .padding(.horizontal, POSPadding.xLarge)
            .padding(.bottom, POSPadding.xLarge)
            .frame(maxHeight: .infinity)

            actionsFooter
                .posPhoneFullScreenButtonPadding(horizontalSizeClass: horizontalSizeClass,
                                                 maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurfaceBright)
        .posRefundModalFrame(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass)
    }
}

// MARK: - Subviews

private extension POSRefundItemsSelectionView {
    var headerView: some View {
        POSRefundNavigationHeader(title: Localization.title,
                                  backAction: onClose,
                                  backAccessibilityLabel: Localization.backButtonAccessibilityLabel)
    }

    var itemsHeaderView: some View {
        HStack(spacing: POSSpacing.small) {
            POSCheckbox(
                isSelected: allItemsSelected,
                onToggle: {
                    let action = allItemsSelected ? "deselected" : "selected"
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.refundSelectAllTapped(action: action))
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

    var actionsFooter: some View {
        VStack(spacing: POSSpacing.small) {
            if let previewErrorMessage {
                Text(previewErrorMessage)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posError)
                    .multilineTextAlignment(.center)
            }

            recoveryButton

            Button(Localization.continueButton) {
                onContinue()
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: reviewPreparationState == .loading))
            .disabled(isContinueDisabled)
        }
    }

    @ViewBuilder
    var recoveryButton: some View {
        switch previewRecovery {
        case .retry:
            Button(Localization.retryButton) {
                onContinue()
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        case .refreshItems:
            Button(Localization.reviewRemainingItemsButton) {
                onRefreshItems()
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        case .dismiss, nil:
            EmptyView()
        }
    }

    /// A failed preview always disables Continue: the same selection produces the same answer, so
    /// the cashier moves on by changing the selection or through the recovery button above it.
    var isContinueDisabled: Bool {
        guard hasSelectedItems else {
            return true
        }
        switch reviewPreparationState {
        case .loading, .previewError:
            return true
        case .idle:
            return false
        }
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
        static let previewError = NSLocalizedString(
            "pos.refundItemsSelectionView.previewError",
            value: "Couldn't calculate the refund total. Please try again.",
            comment: "Error shown on the refund item-selection step when fetching the server-calculated refund total fails"
        )
        static let retryButton = NSLocalizedString(
            "pos.refundItemsSelectionView.retryButton",
            value: "Retry",
            comment: "Button to retry fetching the server-calculated refund total on the refund item-selection step"
        )
        static let reviewRemainingItemsButton = NSLocalizedString(
            "pos.refundItemsSelectionView.reviewRemainingItemsButton",
            value: "Review remaining items",
            comment: "Button to reload the refundable items after the store rejected the refund because the order changed"
        )

        static let backButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundItemsSelectionView.backButton.accessibilityLabel",
            value: "Back",
            comment: "Accessibility label for the back button on the refund items selection screen"
        )

        static let itemsHeaderTitle = NSLocalizedString(
            "pos.refundItemsSelectionView.itemsHeaderTitle",
            value: "Select all items",
            comment: "Header label for items in the refund items selection modal"
        )

        static let itemsSelectedCountFormat = NSLocalizedString(
            "pos.refundItemsSelectionView.itemsSelectedCountFormat",
            value: "(%d selected)",
            comment: "Label showing number of selected items in the refund items selection modal"
        )

        static let selectAllAccessibilityLabel = NSLocalizedString(
            "pos.refundItemsSelectionView.selectAll.accessibilityLabel",
            value: "Select or deselect all items",
            comment: "Accessibility label for the select-all checkbox in the refund items selection modal"
        )
    }
}

#if DEBUG
#Preview("POSRefundItemsSelectionView") {
    POSRefundItemsSelectionView(
        onClose: { },
        onContinue: { },
        onRefreshItems: { }
    )
    .environment(POSPreviewHelpers.makePreviewOrdersModel(state: POSPreviewHelpers.loadedState()))
}
#endif
