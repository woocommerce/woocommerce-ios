import SwiftUI
import struct WooFoundation.WooAnalyticsEvent

enum RefundSelectionState: Identifiable, Equatable {
    case loading
    case loadingError
    case preparationError
    case nothingToRefund
    case itemSelection

    var id: String {
        switch self {
        case .loading: return "loading"
        case .loadingError: return "loadingError"
        case .preparationError: return "preparationError"
        case .nothingToRefund: return "nothingToRefund"
        case .itemSelection: return "itemSelection"
        }
    }

    var abortStep: WooAnalyticsEvent.PointOfSale.RefundStep? {
        switch self {
        case .itemSelection:
            return .selectItems
        case .loading, .loadingError, .preparationError, .nothingToRefund:
            return nil
        }
    }
}

struct POSRefundSelectionFlowView: View {
    let state: RefundSelectionState
    let errorStrings: POSRefundErrorStrings
    let onDismiss: () -> Void
    let onRetryLoading: () -> Void
    let onRetryPreparation: () -> Void
    let onContinue: () -> Void

    var body: some View {
        content
            .environment(\.posRefundPresentationStyle, .fullScreen)
            .toolbar(.hidden, for: .navigationBar)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.posSurfaceBright)
            .posHidesFloatingControl()
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            POSRefundLoadingView(onBack: onDismiss)
        case .loadingError:
            POSRefundErrorView(
                title: errorStrings.loadTitle,
                subtitle: errorStrings.loadSubtitle,
                onRetry: onRetryLoading,
                onCancel: onDismiss,
                onClose: onDismiss
            )
        case .preparationError:
            POSRefundErrorView(
                title: errorStrings.prepareTitle,
                subtitle: errorStrings.prepareSubtitle,
                onRetry: onRetryPreparation,
                onCancel: onDismiss,
                onClose: onDismiss
            )
        case .nothingToRefund:
            POSRefundNothingToRefundView(onClose: onDismiss)
        case .itemSelection:
            POSRefundItemsSelectionView(
                onClose: onDismiss,
                onContinue: onContinue
            )
        }
    }
}

#if DEBUG
#Preview("POSRefundSelectionFlowView - Loading") {
    POSRefundSelectionFlowView(
        state: .loading,
        errorStrings: .preview,
        onDismiss: {},
        onRetryLoading: {},
        onRetryPreparation: {},
        onContinue: {}
    )
}

#Preview("POSRefundSelectionFlowView - Select Items") {
    POSRefundSelectionFlowView(
        state: .itemSelection,
        errorStrings: .preview,
        onDismiss: {},
        onRetryLoading: {},
        onRetryPreparation: {},
        onContinue: {}
    )
    .environment(POSPreviewHelpers.makePreviewOrdersModel(state: POSPreviewHelpers.loadedState()))
}

private extension POSRefundErrorStrings {
    static let preview = POSRefundErrorStrings(
        loadTitle: "Couldn't load refund details",
        loadSubtitle: "Please try again.",
        prepareTitle: "Couldn't prepare refund",
        prepareSubtitle: "Please try again.",
        createTitle: "Failed to create refund",
        createSubtitle: "Please try again."
    )
}
#endif
