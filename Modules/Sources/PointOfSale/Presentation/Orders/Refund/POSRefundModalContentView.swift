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
    case confirmation(POSRefundReviewData)
    case readerConnectionRequired(POSRefundReviewData)
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
        case .confirmation: return "confirmation"
        case .readerConnectionRequired: return "readerConnectionRequired"
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
        case .review:
            return .reviewRefund
        case .confirmation, .readerConnectionRequired:
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

private struct POSRefundCardPresentAlertItem: Identifiable, Equatable {
    let id: String
    let alertType: PointOfSaleCardPresentPaymentAlertType

    static func == (lhs: POSRefundCardPresentAlertItem, rhs: POSRefundCardPresentAlertItem) -> Bool {
        lhs.id == rhs.id
    }
}

private struct POSRefundCardPresentOnboardingItem: Identifiable, Equatable {
    let id: ObjectIdentifier
    let factory: CardPresentPaymentOnboardingViewContainer
    let onCancel: () -> Void

    static func == (lhs: POSRefundCardPresentOnboardingItem, rhs: POSRefundCardPresentOnboardingItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Shared Refund Modal Content

struct POSRefundModalContentView: View {
    let state: RefundModalState
    @Binding var modalState: RefundModalState?
    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(POSPaymentModel.self) private var paymentModel
    @Environment(POSRefundSubmissionModel.self) private var refundSubmissionModel
    @Environment(\.posAnalytics) private var analytics

    /// Dismisses legacy POS modals directly. The order details refund flow now presents as a
    /// full-screen cover and uses `onDismiss`; keep this fallback for previews or reused modal contexts.
    @Environment(\.posModalDismissAction) private var dismissModal

    let order: POSOrder
    let onDismiss: () -> Void
    let onRetryLoading: () -> Void
    let onRetryPreparation: () -> Void
    let onEditRefund: (() -> Void)?
    let showsItemSelection: Bool
    let onRefundSuccess: (() -> Void)?
    let onRefundFailure: ((Error) -> Void)?

    let errorStrings: POSRefundErrorStrings

    @State private var isShowingEmailReceiptView = false
    @State private var isShowingReasonInput = false
    @State private var cardPresentAlertItem: POSRefundCardPresentAlertItem?
    @State private var cardPresentOnboardingItem: POSRefundCardPresentOnboardingItem?
    @State private var currentRefundReason: String?
    @State private var reasonInputReviewData: POSRefundReviewData?

    var body: some View {
        ZStack {
            screenBackgroundColor
                .ignoresSafeArea()

            content
                .environment(\.posRefundPresentationStyle, .fullScreen)
        }
            .ignoresSafeArea(.container, edges: .bottom)
            .posModal(item: $cardPresentAlertItem, onDismiss: {
                cardPresentAlertItem?.alertType.onDismiss?()
            }) { item in
                PointOfSaleCardPresentPaymentAlert(alertType: item.alertType)
                    .posInteractiveDismissDisabled(item.alertType.isDismissDisabled)
            }
            .posModal(item: $cardPresentOnboardingItem, onDismiss: {
                cardPresentOnboardingItem?.onCancel()
            }) { item in
                PointOfSaleCardPresentPaymentOnboardingView(viewModel: .init(
                    onboardingViewContainer: item.factory,
                    onDismissTap: {
                        item.onCancel()
                        cardPresentOnboardingItem = nil
                    }))
            }
            .posFullScreenCover(isPresented: $isShowingEmailReceiptView) {
                POSSendReceiptView(isShowingSendReceiptView: $isShowingEmailReceiptView) { email in
                    try await orderListModel.sendReceipt(order: order, email: email)
                }
                .posHeaderBackButtonIcon(systemName: "xmark")
            }
            .posFullScreenCover(isPresented: $isShowingReasonInput) {
                POSRefundReasonView(
                    initialReason: reasonInputReviewData?.refundReason,
                    onSave: { reason in
                        if var reviewData = reasonInputReviewData {
                            reviewData.refundReason = reason
                            currentRefundReason = reason
                            modalState = .review(reviewData)
                        }
                        isShowingReasonInput = false
                    },
                    onClose: { isShowingReasonInput = false }
                )
                .posHeaderBackButtonIcon(systemName: "xmark")
            }
            .onAppear {
                updateCardPresentAlertItem()
                updateCardPresentOnboardingItem()
            }
            .onChange(of: cardPresentAlertID) { _, _ in
                updateCardPresentAlertItem()
            }
            .onChange(of: cardPresentOnboardingID) { _, _ in
                updateCardPresentOnboardingItem()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            POSRefundLoadingView(onBack: { dismissRefundFlow() })
        case .loadingError:
            POSRefundErrorView(
                title: errorStrings.loadTitle,
                subtitle: errorStrings.loadSubtitle,
                onRetry: onRetryLoading,
                onCancel: { dismissRefundFlow() },
                onClose: { dismissRefundFlow() }
            )
        case .preparationError:
            POSRefundErrorView(
                title: errorStrings.prepareTitle,
                subtitle: errorStrings.prepareSubtitle,
                onRetry: onRetryPreparation,
                onCancel: { dismissRefundFlow() },
                onClose: { dismissRefundFlow() }
            )
        case .nothingToRefund:
            POSRefundNothingToRefundView(onClose: { dismissRefundFlow() })
        case .itemSelection:
            if showsItemSelection {
                POSRefundItemsSelectionView(
                    onClose: {
                        dismissRefundFlow()
                    },
                    onContinue: { navigateToRefundReview() }
                )
            } else {
                EmptyView()
            }
        case .review(let reviewData):
            POSRefundReviewView(
                onClose: {
                    dismissRefundFlow()
                },
                itemsCount: reviewData.itemsCount,
                formattedItemsSubtotal: reviewData.formattedItemsSubtotal,
                formattedTax: reviewData.formattedTax,
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                refundReason: reviewData.refundReason,
                onAddReason: {
                    reasonInputReviewData = reviewData
                    isShowingReasonInput = true
                },
                onContinue: { modalState = .confirmation(reviewData) },
                onEditRefund: onEditRefund
            )
        case .confirmation(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: false,
                onClose: {
                    dismissRefundFlow()
                },
                onConfirm: {
                    handleRefundConfirmation(reviewData: reviewData)
                },
                onBack: { modalState = .review(reviewData) }
            )
        case .readerConnectionRequired(let reviewData):
            POSRefundReaderDisconnectedView(
                onConnect: { startProcessingRefund(reviewData: reviewData) },
                onCancel: { dismissModal?() },
                onBack: { modalState = .confirmation(reviewData) }
            )
        case .processing(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: true,
                submissionState: refundSubmissionModel.state,
                onClose: {},
                onConfirm: {},
                onBack: {}
            )
        case .success(let reviewData):
            POSRefundSuccessView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                customerEmail: reviewData.customerEmail,
                onDone: { dismissRefundFlow() },
                onEmailReceipt: { isShowingEmailReceiptView = true }
            )
        case .error(let reviewData):
            POSRefundErrorView(
                title: errorStrings.createTitle,
                subtitle: errorStrings.createSubtitle,
                onRetry: { modalState = .confirmation(reviewData) },
                onCancel: { dismissRefundFlow() },
                onClose: { dismissRefundFlow() }
            )
        }
    }

    private var screenBackgroundColor: Color {
        switch state {
        case .processing:
            switch refundSubmissionModel.state {
            case .processingReader, .displayingReaderMessage:
                return .posPrimary
            case .cardPresentEvent(.processing), .cardPresentEvent(.displayReaderMessage), .cardPresentEvent(.paymentSuccess):
                return .posPrimary
            case .submittingCardPresent:
                return .posPrimary
            case .idle, .loading, .onboarding, .cardPresentEvent, .preparingReader, .waitingForCard,
                    .submitting, .retryableError, .nonRetryableError, .completed:
                return .posSurfaceBright
            }
        case .loading, .loadingError, .preparationError, .nothingToRefund, .itemSelection, .review, .confirmation,
                .success, .error:
            return .posSurfaceBright
        }
    }

    private var cardPresentAlertID: String? {
        guard case .processing = state,
              case .cardPresentEvent(let eventDetails) = refundSubmissionModel.state else {
            return nil
        }
        return eventDetails.posRefundConnectionAlertID
    }

    private var cardPresentOnboardingID: ObjectIdentifier? {
        guard case .processing = state,
              case .onboarding(let factory, _) = refundSubmissionModel.state else {
            return nil
        }
        return ObjectIdentifier(factory)
    }

    private func dismissRefundFlow() {
        if let dismissModal {
            dismissModal()
        } else {
            onDismiss()
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

    private func updateCardPresentAlertItem() {
        guard case .processing(let reviewData) = state,
              case .cardPresentEvent(let eventDetails) = refundSubmissionModel.state,
              let alertID = eventDetails.posRefundConnectionAlertID,
              let alertType = cardPresentAlertType(for: eventDetails, reviewData: reviewData) else {
            cardPresentAlertItem = nil
            return
        }

        cardPresentAlertItem = POSRefundCardPresentAlertItem(id: alertID, alertType: alertType)
    }

    private func updateCardPresentOnboardingItem() {
        guard case .processing = state,
              case .onboarding(let factory, let onCancel) = refundSubmissionModel.state else {
            cardPresentOnboardingItem = nil
            return
        }

        cardPresentOnboardingItem = POSRefundCardPresentOnboardingItem(
            id: ObjectIdentifier(factory),
            factory: factory,
            onCancel: onCancel
        )
    }

    private func cardPresentAlertType(for eventDetails: CardPresentPaymentEventDetails,
                                      reviewData: POSRefundReviewData) -> PointOfSaleCardPresentPaymentAlertType? {
        guard let presentationStyle = PointOfSaleCardPresentPaymentEventPresentationStyle(
            for: eventDetails,
            dependencies: .init(
                tryPaymentAgainBackToCheckoutAction: { modalState = .confirmation(reviewData) },
                nonRetryableErrorExitAction: { dismissRefundFlow() },
                formattedOrderTotalPrice: reviewData.formattedRefundTotal,
                paymentCaptureErrorTryAgainAction: { modalState = .confirmation(reviewData) },
                paymentCaptureErrorNewOrderAction: { dismissRefundFlow() },
                paymentIntentCreationErrorEditOrderAction: { modalState = .review(reviewData) },
                dismissReaderConnectionModal: { cardPresentAlertItem = nil }
            )) else {
            return nil
        }

        guard case .alert(let alertType) = presentationStyle else {
            return nil
        }
        return alertType
    }

    @MainActor
    private func processRefund(reviewData: POSRefundReviewData) async {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.refundProcessingStarted())
        do {
            try await orderListModel.ordersController.processRefund(reason: reviewData.refundReason)
            analytics.track(event: WooAnalyticsEvent.PointOfSale.refundProcessingSuccess())
            refundSubmissionModel.reset()
            modalState = .success(reviewData)
            onRefundSuccess?()
        } catch POSRefundSubmissionError.canceledByUser {
            refundSubmissionModel.reset()
            modalState = .confirmation(reviewData)
        } catch {
            DDLogError("⛔️ Failed to process POS refund: \(error)")
            analytics.track(event: WooAnalyticsEvent.PointOfSale.refundProcessingFailed(error: error))
            onRefundFailure?(error)
            refundSubmissionModel.reset()
            modalState = .error(reviewData)
        }
    }

    @MainActor
    private func handleRefundConfirmation(reviewData: POSRefundReviewData) {
        let refundType = reviewData.isFullRefund ? "full" : "partial"
        let hasReason = reviewData.refundReason?.isEmpty == false
        analytics.track(event: WooAnalyticsEvent.PointOfSale.refundConfirmTapped(refundType: refundType, hasReason: hasReason))

        if shouldRequireReaderConnection() {
            modalState = .readerConnectionRequired(reviewData)
            return
        }

        startProcessingRefund(reviewData: reviewData)
    }

    @MainActor
    private func startProcessingRefund(reviewData: POSRefundReviewData) {
        modalState = .processing(reviewData)
        Task { @MainActor in
            await processRefund(reviewData: reviewData)
        }
    }

    private func shouldRequireReaderConnection() -> Bool {
        guard orderListModel.ordersController.currentRefundRequiresCardPresentRefund else {
            return false
        }

        return paymentModel.cardReaderConnectionStatus == .disconnected
    }
}

private extension CardPresentPaymentEventDetails {
    var posRefundConnectionAlertID: String? {
        switch self {
        case .scanningForReaders:
            return "scanningForReaders"
        case .scanningFailed(let error, _):
            return "scanningFailed-\(error.localizedDescription)"
        case .bluetoothRequired(let error, _):
            return "bluetoothRequired-\(error.localizedDescription)"
        case .connectingToReader:
            return "connectingToReader"
        case .connectingFailed(let error, _, _):
            return "connectingFailed-\(error.localizedDescription)"
        case .connectingFailedNonRetryable(let error, _):
            return "connectingFailedNonRetryable-\(error.localizedDescription)"
        case .connectingFailedUpdatePostalCode:
            return "connectingFailedUpdatePostalCode"
        case .connectingFailedChargeReader:
            return "connectingFailedChargeReader"
        case .connectingFailedUpdateAddress(let adminURL, _, _, _):
            return "connectingFailedUpdateAddress-\(adminURL.absoluteString)"
        case .foundReader(let name, _, _, _):
            return "foundReader-\(name)"
        case .foundMultipleReaders(let readerIDs, _):
            return "foundMultipleReaders-\(readerIDs.joined(separator: ","))"
        case .updateProgress(let requiredUpdate, let progress, _):
            return "updateProgress-\(requiredUpdate)-\(progress)"
        case .updateFailed:
            return "updateFailed"
        case .updateFailedNonRetryable:
            return "updateFailedNonRetryable"
        case .updateFailedLowBattery(let batteryLevel, _, _):
            return "updateFailedLowBattery-\(batteryLevel)"
        case .connectionSuccess:
            return "connectionSuccess"
        case .locationRequestPreAlert:
            return "locationRequestPreAlert"
        case .locationRequired:
            return "locationRequired"
        case .selectSearchType, .validatingOrder, .preparingForPayment,
                .tapSwipeOrInsertCard, .cardInserted, .processing,
                .displayReaderMessage, .paymentSuccess, .paymentError,
                .paymentCaptureError, .paymentIntentCreationError,
                .cancelledOnReader:
            return nil
        }
    }
}
