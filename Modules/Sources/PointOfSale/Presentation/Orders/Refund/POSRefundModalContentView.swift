import CocoaLumberjackSwift
import SwiftUI
import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSOrder

// MARK: - Refund Modal State

enum RefundModalState: Identifiable, Equatable {
    case review(POSRefundReviewData)
    case confirmation(POSRefundReviewData)
    case readerConnectionRequired(POSRefundReviewData)
    case processing(POSRefundReviewData)
    case success(POSRefundReviewData)
    case error(POSRefundReviewData)

    var id: String {
        switch self {
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
    let onReturnToSelection: () -> Void
    let initialRefundReason: String?
    let onRefundReasonChanged: ((String?) -> Void)?
    let onRefundSuccess: (() -> Void)?
    let onRefundFailure: ((Error) -> Void)?

    let errorStrings: POSRefundErrorStrings

    @State private var isShowingEmailReceiptView = false
    @State private var isShowingReasonInput = false
    @State private var cardPresentAlertItem: POSRefundCardPresentAlertItem?
    @State private var cardPresentOnboardingItem: POSRefundCardPresentOnboardingItem?
    @State private var currentRefundReason: String?
    @State private var reasonInputReviewData: POSRefundReviewData?
    @State private var isDismissingAfterAmbiguousRefund = false

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
                            onRefundReasonChanged?(reason)
                            modalState = .review(reviewData)
                        }
                        isShowingReasonInput = false
                    },
                    onClose: { isShowingReasonInput = false }
                )
                .posHeaderBackButtonIcon(systemName: "xmark")
            }
            .onAppear {
                currentRefundReason = initialRefundReason
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
        case .review(let reviewData):
            POSRefundReviewView(
                onClose: {
                    onReturnToSelection()
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
                onContinue: { modalState = .confirmation(reviewData) }
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
                onCancel: { dismissRefundFlow() },
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
                onBack: { returnToRefundConfirmation(reviewData: reviewData) },
                shouldUseCardPresentCompletionStyle: orderListModel.ordersController.currentRefundRequiresCardPresentRefund,
                onPaymentCaptureErrorCancel: { cancelPayment in
                    handleAmbiguousCardPresentRefund(cancelPayment: cancelPayment)
                }
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
            let isCardPresentRefundError = orderListModel.ordersController.currentRefundRequiresCardPresentRefund
            let dismissError = {
                if isCardPresentRefundError {
                    dismissRefundFlowAndRefreshOrder()
                } else {
                    dismissRefundFlow()
                }
            }
            POSRefundErrorView(
                title: isCardPresentRefundError ? Localization.cardPresentCreateErrorTitle : errorStrings.createTitle,
                subtitle: isCardPresentRefundError ? Localization.cardPresentCreateErrorSubtitle : errorStrings.createSubtitle,
                onRetry: isCardPresentRefundError ? nil : { modalState = .confirmation(reviewData) },
                cancelButtonTitle: isCardPresentRefundError ? Localization.backToOrderButton : nil,
                onCancel: dismissError,
                onClose: dismissError
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
        case .review, .confirmation, .readerConnectionRequired, .success, .error:
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

    @MainActor
    private func dismissRefundFlowAndRefreshOrder() {
        dismissRefundFlow()
        refreshOrderAfterPotentialCardPresentRefund()
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
        guard case .processing(let reviewData) = state,
              case .onboarding(let factory, let onCancel) = refundSubmissionModel.state else {
            cardPresentOnboardingItem = nil
            return
        }

        cardPresentOnboardingItem = POSRefundCardPresentOnboardingItem(
            id: ObjectIdentifier(factory),
            factory: factory,
            onCancel: {
                returnToRefundConfirmation(reviewData: reviewData)
                onCancel()
            }
        )
    }

    private func cardPresentAlertType(for eventDetails: CardPresentPaymentEventDetails,
                                      reviewData: POSRefundReviewData) -> PointOfSaleCardPresentPaymentAlertType? {
        guard let presentationStyle = PointOfSaleCardPresentPaymentEventPresentationStyle(
            for: eventDetails,
            dependencies: .init(
                tryPaymentAgainBackToCheckoutAction: { returnToRefundConfirmation(reviewData: reviewData) },
                nonRetryableErrorExitAction: { dismissRefundFlow() },
                formattedOrderTotalPrice: reviewData.formattedRefundTotal,
                paymentCaptureErrorTryAgainAction: { returnToRefundConfirmation(reviewData: reviewData) },
                paymentCaptureErrorNewOrderAction: { dismissRefundFlow() },
                paymentIntentCreationErrorEditOrderAction: {
                    refundSubmissionModel.reset()
                    modalState = .review(reviewData)
                },
                dismissReaderConnectionModal: {
                    let shouldReturnToConfirmation = currentCardPresentEventCanCancel
                    cardPresentAlertItem = nil
                    if shouldReturnToConfirmation {
                        returnToRefundConfirmation(reviewData: reviewData)
                    }
                }
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
            guard !isDismissingAfterAmbiguousRefund else {
                return
            }
            returnToRefundConfirmation(reviewData: reviewData)
        } catch {
            guard !isDismissingAfterAmbiguousRefund else {
                return
            }
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

    private func returnToRefundConfirmation(reviewData: POSRefundReviewData) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            cardPresentAlertItem = nil
            cardPresentOnboardingItem = nil
            refundSubmissionModel.reset()
            modalState = .confirmation(reviewData)
        }
    }

    @MainActor
    private func handleAmbiguousCardPresentRefund(cancelPayment: @escaping () -> Void) {
        // At this point the card-present refund may already have reached the gateway, but the app could not
        // confirm the final result. Returning to confirmation would leave a live submit button that could create
        // a duplicate refund, so exit the flow and refresh the order/refunds instead.
        isDismissingAfterAmbiguousRefund = true
        cardPresentAlertItem = nil
        cardPresentOnboardingItem = nil
        refundSubmissionModel.reset()
        cancelPayment()
        dismissRefundFlowAndRefreshOrder()

        // The submission task may still report cancellation/failure after dismissing; isDismissingAfterAmbiguousRefund
        // keeps that late callback from reopening the modal or tracking a normal refund failure.
    }

    private func refreshOrderAfterPotentialCardPresentRefund() {
        Task { @MainActor in
            do {
                try await orderListModel.ordersController.updateOrder(orderID: order.id)
            } catch {
                DDLogError("⛔️ Failed to refresh POS order after card-present refund outcome: \(error)")
            }
            await orderListModel.ordersController.loadOrderRefunds()
        }
    }

    private var currentCardPresentEventCanCancel: Bool {
        guard case .cardPresentEvent(let eventDetails) = refundSubmissionModel.state else {
            return false
        }
        return eventDetails.posRefundCancelAction != nil
    }

    private func shouldRequireReaderConnection() -> Bool {
        guard orderListModel.ordersController.currentRefundRequiresCardPresentRefund else {
            return false
        }

        if case .connected = paymentModel.cardReaderConnectionStatus {
            return false
        }
        return true
    }
}

// MARK: - Localization

private extension POSRefundModalContentView {
    enum Localization {
        static let cardPresentCreateErrorTitle = NSLocalizedString(
            "pos.refundModalContentView.cardPresentCreateError.title",
            value: "Couldn't confirm refund",
            comment: "Title shown when POS cannot confirm whether a card-present refund was recorded successfully."
        )

        static let cardPresentCreateErrorSubtitle = NSLocalizedString(
            "pos.refundModalContentView.cardPresentCreateError.subtitle",
            value: "Go back to the order and check it before trying again.",
            comment: "Subtitle shown when POS cannot confirm whether a card-present refund was recorded successfully."
        )

        static let backToOrderButton = NSLocalizedString(
            "pos.refundModalContentView.cardPresentCreateError.backToOrderButton",
            value: "Back to order",
            comment: "Button to leave the card-present refund error screen and return to the order."
        )
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
            let batteryLevelDescription: String
            if let batteryLevel {
                batteryLevelDescription = "\(batteryLevel)"
            } else {
                batteryLevelDescription = "nil"
            }
            return "updateFailedLowBattery-\(batteryLevelDescription)"
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
