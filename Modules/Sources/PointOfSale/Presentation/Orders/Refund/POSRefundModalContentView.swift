import CocoaLumberjackSwift
import SwiftUI
import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSOrder

// MARK: - Refund Modal State

enum RefundModalState: Identifiable, Equatable {
    case loading
    case loadingError
    case preparationError
    case nothingToRefund
    case itemSelection
    case review(POSRefundReviewData)
    case reasonInput(POSRefundReviewData)
    case confirmation(POSRefundReviewData)
    case processing(POSRefundReviewData)
    case success(POSRefundReviewData)
    case error(POSRefundReviewData)

    var id: String {
        switch self {
        case .loading: return "loading"
        case .loadingError: return "loadingError"
        case .preparationError: return "preparationError"
        case .nothingToRefund: return "nothingToRefund"
        case .itemSelection: return "itemSelection"
        case .review: return "review"
        case .reasonInput: return "reasonInput"
        case .confirmation: return "confirmation"
        case .processing: return "processing"
        case .success: return "success"
        case .error: return "error"
        }
    }

    /// Returns the analytics step for abort tracking
    var abortStep: WooAnalyticsEvent.PointOfSale.RefundStep? {
        switch self {
        case .itemSelection:
            return .selectItems
        case .review, .reasonInput:
            return .reviewRefund
        case .confirmation:
            return .confirmRefund
        default:
            return nil
        }
    }
}

// MARK: - Error Strings

struct POSRefundErrorStrings {
    let loadTitle: String
    let loadSubtitle: String
    let prepareTitle: String
    let prepareSubtitle: String
    let createTitle: String
    let createSubtitle: String
}

// MARK: - Shared Refund Modal Content

struct POSRefundModalContentView: View {
    let state: RefundModalState
    @Binding var modalState: RefundModalState?
    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.posAnalytics) private var analytics

    /// Dismisses the modal directly, bypassing the `onChange(of:)` chain in `POSModalViewModifier`
    /// which can fail to fire when the view is inside a pushed navigation destination.
    @Environment(\.posModalDismissAction) private var dismissModal

    let order: POSOrder
    let onRetryLoading: () -> Void
    let onRetryPreparation: () -> Void
    let onEditRefund: (() -> Void)?
    let showsItemSelection: Bool
    let onRefundSuccess: (() -> Void)?
    let onRefundFailure: ((Error) -> Void)?

    let errorStrings: POSRefundErrorStrings

    @State private var isShowingEmailReceiptView = false
    @State private var currentRefundReason: String?

    var body: some View {
        content
            .posFullScreenCover(isPresented: $isShowingEmailReceiptView) {
                POSSendReceiptView(isShowingSendReceiptView: $isShowingEmailReceiptView) { email in
                    try await orderListModel.sendReceipt(order: order, email: email)
                }
                .posHeaderBackButtonIcon(systemName: "xmark")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            POSRefundLoadingView()
        case .loadingError:
            POSRefundErrorView(
                title: errorStrings.loadTitle,
                subtitle: errorStrings.loadSubtitle,
                onRetry: onRetryLoading,
                onCancel: { dismissModal?() },
                onClose: { dismissModal?() }
            )
        case .preparationError:
            POSRefundErrorView(
                title: errorStrings.prepareTitle,
                subtitle: errorStrings.prepareSubtitle,
                onRetry: onRetryPreparation,
                onCancel: { dismissModal?() },
                onClose: { dismissModal?() }
            )
        case .nothingToRefund:
            POSRefundNothingToRefundView(onClose: { dismissModal?() })
        case .itemSelection:
            if showsItemSelection {
                POSRefundItemsSelectionView(
                    onClose: {
                        dismissModal?()
                    },
                    onContinue: { navigateToRefundReview() }
                )
            } else {
                EmptyView()
            }
        case .review(let reviewData):
            POSRefundReviewView(
                onClose: {
                    dismissModal?()
                },
                itemsCount: reviewData.itemsCount,
                formattedItemsSubtotal: reviewData.formattedItemsSubtotal,
                formattedTax: reviewData.formattedTax,
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                refundReason: reviewData.refundReason,
                onAddReason: { modalState = .reasonInput(reviewData) },
                onContinue: { modalState = .confirmation(reviewData) },
                onEditRefund: onEditRefund
            )
        case .reasonInput(let reviewData):
            POSRefundReasonView(
                initialReason: reviewData.refundReason,
                onSave: { reason in
                    var updated = reviewData
                    updated.refundReason = reason
                    currentRefundReason = reason
                    modalState = .review(updated)
                },
                onBack: { modalState = .review(reviewData) }
            )
        case .confirmation(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: false,
                onClose: {
                    dismissModal?()
                },
                onConfirm: {
                    let refundType = reviewData.isFullRefund ? "full" : "partial"
                    let hasReason = reviewData.refundReason?.isEmpty == false
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.refundConfirmTapped(refundType: refundType, hasReason: hasReason))
                    modalState = .processing(reviewData)
                    Task { @MainActor in
                        await processRefund(reviewData: reviewData)
                    }
                },
                onBack: { modalState = .review(reviewData) }
            )
        case .processing(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: true,
                onClose: {},
                onConfirm: {},
                onBack: {}
            )
        case .success(let reviewData):
            POSRefundSuccessView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                customerEmail: reviewData.customerEmail,
                onDone: { dismissModal?() },
                onEmailReceipt: { isShowingEmailReceiptView = true },
                onClose: { dismissModal?() }
            )
        case .error(let reviewData):
            POSRefundErrorView(
                title: errorStrings.createTitle,
                subtitle: errorStrings.createSubtitle,
                onRetry: { modalState = .confirmation(reviewData) },
                onCancel: { dismissModal?() },
                onClose: { dismissModal?() }
            )
        }
    }

    private func navigateToRefundReview() {
        guard var reviewData = orderListModel.ordersController.preparePOSRefundReviewData() else {
            modalState = .preparationError
            return
        }
        reviewData.refundReason = currentRefundReason
        modalState = .review(reviewData)
    }

    @MainActor
    private func processRefund(reviewData: POSRefundReviewData) async {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.refundProcessingStarted())
        do {
            try await orderListModel.ordersController.processRefund(reason: reviewData.refundReason)
            analytics.track(event: WooAnalyticsEvent.PointOfSale.refundProcessingSuccess())
            modalState = .success(reviewData)
            onRefundSuccess?()
        } catch {
            DDLogError("⛔️ Failed to process POS refund: \(error)")
            analytics.track(event: WooAnalyticsEvent.PointOfSale.refundProcessingFailed(error: error))
            onRefundFailure?(error)
            modalState = .error(reviewData)
        }
    }
}
