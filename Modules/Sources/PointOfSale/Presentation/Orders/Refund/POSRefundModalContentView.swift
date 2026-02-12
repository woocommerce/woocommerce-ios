import CocoaLumberjackSwift
import SwiftUI

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

    let onEmailReceipt: () -> Void
    let onRetryLoading: () -> Void
    let onRetryPreparation: () -> Void
    let onEditRefund: (() -> Void)?
    let showsItemSelection: Bool
    let onRefundSuccess: (() -> Void)?

    let errorStrings: POSRefundErrorStrings

    var body: some View {
        content
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
                onCancel: { modalState = nil },
                onClose: { modalState = nil }
            )
        case .preparationError:
            POSRefundErrorView(
                title: errorStrings.prepareTitle,
                subtitle: errorStrings.prepareSubtitle,
                onRetry: onRetryPreparation,
                onCancel: { modalState = nil },
                onClose: { modalState = nil }
            )
        case .nothingToRefund:
            POSRefundNothingToRefundView(onClose: { modalState = nil })
        case .itemSelection:
            if showsItemSelection {
                POSRefundItemsSelectionView(
                    onClose: { modalState = nil },
                    onContinue: { navigateToRefundReview() }
                )
            } else {
                assertionFailure("Unexpected .itemSelection state when showsItemSelection is false")
                EmptyView()
            }
        case .review(let reviewData):
            POSRefundReviewView(
                onClose: { modalState = nil },
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
                    modalState = .review(updated)
                },
                onBack: { modalState = .review(reviewData) },
                onClose: { modalState = nil }
            )
        case .confirmation(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: false,
                onClose: { modalState = nil },
                onConfirm: {
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
                onDone: { modalState = nil },
                onEmailReceipt: {
                    modalState = nil
                    onEmailReceipt()
                },
                onClose: { modalState = nil }
            )
        case .error(let reviewData):
            POSRefundErrorView(
                title: errorStrings.createTitle,
                subtitle: errorStrings.createSubtitle,
                onRetry: { modalState = .confirmation(reviewData) },
                onCancel: { modalState = nil },
                onClose: { modalState = nil }
            )
        }
    }

    private func navigateToRefundReview() {
        guard let reviewData = orderListModel.ordersController.preparePOSRefundReviewData() else {
            modalState = .preparationError
            return
        }
        modalState = .review(reviewData)
    }

    @MainActor
    private func processRefund(reviewData: POSRefundReviewData) async {
        do {
            try await orderListModel.ordersController.processRefund(reason: reviewData.refundReason)
            modalState = .success(reviewData)
            onRefundSuccess?()
        } catch {
            DDLogError("⛔️ Failed to process POS refund: \(error)")
            modalState = .error(reviewData)
        }
    }
}
