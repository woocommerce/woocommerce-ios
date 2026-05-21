import SwiftUI

struct POSRefundConfirmationView: View {
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let isProcessing: Bool
    var submissionState: POSRefundSubmissionState = .idle
    let onClose: () -> Void
    let onConfirm: () -> Void
    let onBack: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Namespace private var paymentMessageNamespace

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            if shouldShowHeader {
                headerView
            }
            if shouldShowMessageView {
                messageView
            }
            if isProcessing {
                processingSection
            } else {
                buttonsSection
            }
        }
        .background(backgroundColor)
        .posRefundModalFrame(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass)
    }
}

// MARK: - Subviews

private extension POSRefundConfirmationView {
    var headerView: some View {
        HStack {
            Text(String(format: isProcessing ? Localization.processingTitleFormat : Localization.titleFormat, formattedRefundTotal))
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .lineLimit(1)
                .minimumScaleFactor(horizontalSizeClass == .compact ? 0.7 : 1.0)
            Spacer()
            if let closeAction = headerCloseAction {
                Button {
                    closeAction()
                } label: {
                    Text(Image(systemName: "xmark"))
                        .font(.posButtonSymbolLarge)
                }
                .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
            }
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var shouldShowHeader: Bool {
        primaryBackgroundCardPresentMessageType == nil
    }

    var backgroundColor: Color {
        primaryBackgroundCardPresentMessageType == nil ? .posSurfaceBright : .posPrimary
    }

    var primaryBackgroundCardPresentMessageType: POSRefundCardPresentMessageType? {
        switch submissionState {
        case .cardPresentEvent(let eventDetails):
            guard let messageType = refundMessageType(for: eventDetails),
                  messageType.usesPrimaryBackground else {
                return nil
            }
            return messageType
        case .processingReader:
            return .processing(.processing)
        case .displayingReaderMessage(let message):
            return .displayReaderMessage(.displayReaderMessage(message))
        case .idle, .loading, .onboarding, .preparingReader, .waitingForCard, .submitting, .retryableError, .nonRetryableError, .completed:
            return nil
        }
    }

    var headerCloseAction: (() -> Void)? {
        guard isProcessing else {
            return onClose
        }
        return processingCancelAction
    }

    var processingCancelAction: (() -> Void)? {
        switch submissionState {
        case .onboarding(_, let onCancel):
            return onCancel
        case .cardPresentEvent(let eventDetails):
            return eventDetails.posRefundCancelAction
        case .preparingReader(let cancel),
                .waitingForCard(_, let cancel):
            return cancel
        case .idle, .loading, .processingReader, .displayingReaderMessage, .submitting, .retryableError, .nonRetryableError, .completed:
            return nil
        }
    }

    var messageView: some View {
        Text(isProcessing
             ? Localization.processingMessage
             : String(format: Localization.confirmationMessageFormat,
                      formattedRefundTotal,
                      paymentMethodDescription))
            .font(.posBodyLargeRegular())
            .foregroundColor(Color.posOnSurface)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, POSPadding.xLarge)
    }

    var shouldShowMessageView: Bool {
        switch submissionState {
        case .onboarding, .cardPresentEvent, .preparingReader, .waitingForCard, .processingReader, .displayingReaderMessage:
            return false
        case .idle, .loading, .submitting, .retryableError, .nonRetryableError, .completed:
            return true
        }
    }

    @ViewBuilder
    var processingSection: some View {
        switch submissionState {
        case .onboarding(let factory, let onCancel):
            PointOfSaleCardPresentPaymentOnboardingView(viewModel: .init(
                onboardingViewContainer: factory,
                onDismissTap: onCancel))
            .padding(POSPadding.xLarge)
        case .cardPresentEvent(let eventDetails):
            if let messageType = refundMessageType(for: eventDetails) {
                cardPresentMessageView(messageType)
            } else if let alertType = cardPresentAlertType(for: eventDetails) {
                PointOfSaleCardPresentPaymentAlert(alertType: alertType)
                    .padding(POSPadding.xLarge)
            } else {
                loadingSection
            }
        case .preparingReader:
            POSPaymentLoadingView(title: Localization.preparingReaderTitle,
                                  message: Localization.preparingReaderMessage,
                                  animation: .init(namespace: paymentMessageNamespace))
            .padding(POSPadding.xLarge)
        case .waitingForCard(let inputMethods, _):
            cardPresentMessageView(.waitingForCard(.init(inputMethods: inputMethods)))
        case .processingReader:
            cardPresentMessageView(.processing(.processing))
        case .displayingReaderMessage(let message):
            cardPresentMessageView(.displayReaderMessage(.displayReaderMessage(message)))
        case .retryableError(let error, let retry, let cancel):
            POSRefundErrorView(title: Localization.readerErrorTitle,
                               subtitle: error.localizedDescription,
                               onRetry: retry,
                               onCancel: cancel,
                               onClose: cancel)
        case .nonRetryableError(let error, let dismiss):
            POSRefundErrorView(title: Localization.readerErrorTitle,
                               subtitle: error.localizedDescription,
                               onRetry: nil,
                               onCancel: dismiss,
                               onClose: dismiss)
        case .idle, .loading, .submitting, .completed:
            loadingSection
        }
    }

    var loadingSection: some View {
        VStack {
            ProgressView()
                .progressViewStyle(POSRefundModalLayout.progressViewStyle)
        }
        .frame(maxWidth: .infinity)
        .padding(POSPadding.xLarge)
    }

    func cardPresentMessageView(_ messageType: POSRefundCardPresentMessageType) -> some View {
        POSRefundCardPresentMessageView(messageType: messageType,
                                        animation: .init(namespace: paymentMessageNamespace))
        .padding(POSPadding.xLarge)
        .frame(maxWidth: .infinity)
        .background(messageType.usesPrimaryBackground ? Color.posPrimary : Color.clear)
    }

    func refundMessageType(for eventDetails: CardPresentPaymentEventDetails) -> POSRefundCardPresentMessageType? {
        switch eventDetails {
        case .validatingOrder:
            return .preparingReader(.checkingRefund)
        case .preparingForPayment:
            return .preparingReader(.preparingReader)
        case .tapSwipeOrInsertCard(let inputMethods, _):
            return .waitingForCard(.init(inputMethods: inputMethods))
        case .cardInserted:
            return .cardInserted(.cardInserted)
        case .processing:
            return .processing(.processing)
        case .displayReaderMessage(let message):
            return .displayReaderMessage(.displayReaderMessage(message))
        case .cancelledOnReader:
            return .cancelledOnReader(.cancelledOnReader(backToRefund: onBack))
        case .paymentError(let error, let retryApproach, let cancelPayment):
            return .error(.init(error: error,
                                retryAction: retryAction(for: retryApproach),
                                cancelAction: cancelPayment))
        case .paymentCaptureError(let cancelPayment):
            return .error(.init(error: POSRefundCardPresentPresentationError.unableToConfirmRefund,
                                retryAction: nil,
                                cancelAction: cancelPayment))
        case .paymentIntentCreationError(let error, let cancelPayment):
            return .error(.init(error: error,
                                retryAction: nil,
                                cancelAction: cancelPayment))
        case .scanningForReaders, .scanningFailed, .bluetoothRequired, .connectingToReader, .connectingFailed,
                .connectingFailedNonRetryable, .connectingFailedUpdatePostalCode, .connectingFailedChargeReader,
                .connectingFailedUpdateAddress, .selectSearchType, .foundReader, .foundMultipleReaders, .updateProgress,
                .updateFailed, .updateFailedNonRetryable, .updateFailedLowBattery, .connectionSuccess, .paymentSuccess,
                .locationRequestPreAlert, .locationRequired:
            return nil
        }
    }

    func retryAction(for retryApproach: CardPresentPaymentRetryApproach) -> (() -> Void)? {
        switch retryApproach {
        case .tryAgain(let retryAction),
                .tryAnotherPaymentMethod(let retryAction):
            return retryAction
        case .dontRetry:
            return nil
        }
    }

    func cardPresentAlertType(for eventDetails: CardPresentPaymentEventDetails) -> PointOfSaleCardPresentPaymentAlertType? {
        guard let presentationStyle = PointOfSaleCardPresentPaymentEventPresentationStyle(
            for: eventDetails,
            dependencies: .init(
                tryPaymentAgainBackToCheckoutAction: onBack,
                nonRetryableErrorExitAction: onClose,
                formattedOrderTotalPrice: formattedRefundTotal,
                paymentCaptureErrorTryAgainAction: onBack,
                paymentCaptureErrorNewOrderAction: onClose,
                paymentIntentCreationErrorEditOrderAction: onBack,
                dismissReaderConnectionModal: {}
            )) else {
            return nil
        }

        guard case .alert(let alertType) = presentationStyle else {
            return nil
        }
        return alertType
    }

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(Localization.confirmButton, action: onConfirm)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.backButton, action: onBack)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .posPhoneFullScreenButtonPadding(horizontalSizeClass: horizontalSizeClass)
    }
}

private enum POSRefundCardPresentPresentationError: LocalizedError {
    case unableToConfirmRefund

    var errorDescription: String? {
        switch self {
        case .unableToConfirmRefund:
            return NSLocalizedString(
                "pos.refundConfirmationView.cardPresent.unableToConfirmRefund",
                value: "We’re unable to confirm that the refund succeeded. Check the order before trying again.",
                comment: "Error shown when POS cannot confirm whether a card reader refund succeeded."
            )
        }
    }
}

private extension CardPresentPaymentEventDetails {
    var posRefundCancelAction: (() -> Void)? {
        switch self {
        case .scanningForReaders(let endSearch),
                .scanningFailed(_, let endSearch),
                .bluetoothRequired(_, let endSearch),
                .connectingFailedNonRetryable(_, let endSearch):
            return endSearch
        case .connectingFailed(_, _, let endSearch),
                .connectingFailedUpdatePostalCode(_, let endSearch),
                .connectingFailedChargeReader(_, let endSearch),
                .connectingFailedUpdateAddress(_, _, _, let endSearch):
            return endSearch
        case .selectSearchType(_, _, let endSearch),
                .foundReader(_, _, _, let endSearch):
            return endSearch
        case .foundMultipleReaders(_, let selectionHandler):
            return {
                selectionHandler(nil)
            }
        case .updateProgress(_, _, let cancelUpdate):
            return cancelUpdate
        case .updateFailed(_, let cancelUpdate),
                .updateFailedNonRetryable(let cancelUpdate),
                .updateFailedLowBattery(_, _, let cancelUpdate):
            return cancelUpdate
        case .preparingForPayment(let cancelPayment),
                .tapSwipeOrInsertCard(_, let cancelPayment),
                .cardInserted(let cancelPayment),
                .paymentError(_, _, let cancelPayment),
                .paymentCaptureError(let cancelPayment),
                .paymentIntentCreationError(_, let cancelPayment),
                .validatingOrder(let cancelPayment):
            return cancelPayment
        case .locationRequired(let cancel):
            return cancel
        case .connectingToReader, .connectionSuccess, .paymentSuccess, .processing,
                .locationRequestPreAlert,
                .displayReaderMessage, .cancelledOnReader:
            return nil
        }
    }
}

// MARK: - Localization

private extension POSRefundConfirmationView {
    enum Localization {
        static let titleFormat = NSLocalizedString(
            "pos.refundConfirmationView.titleFormat",
            value: "Refund %@",
            comment: "Title for the refund confirmation modal. %@ is the formatted refund amount."
        )

        static let processingTitleFormat = NSLocalizedString(
            "pos.refundConfirmationView.processingTitleFormat",
            value: "Refunding %@",
            comment: "Title for the refund confirmation modal while processing. %@ is the formatted refund amount."
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundConfirmationView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on refund confirmation modal"
        )

        static let confirmationMessageFormat = NSLocalizedString(
            "pos.refundConfirmationView.confirmationMessageFormat.1",
            value: "Are you sure you wish to refund %1$@ %2$@? This action cannot be undone.",
            comment: "Confirmation message for the refund. %1$@ is the formatted amount, %2$@ is the payment method description."
        )

        static let processingMessage = NSLocalizedString(
            "pos.refundConfirmationView.processingMessage",
            value: "Please wait while we process the refund.",
            comment: "Message shown while the refund is being processed."
        )

        static let preparingReaderTitle = NSLocalizedString(
            "pos.refundConfirmationView.preparingReaderTitle",
            value: "Preparing reader",
            comment: "Title shown while preparing a card reader for an in-person refund."
        )

        static let preparingReaderMessage = NSLocalizedString(
            "pos.refundConfirmationView.preparingReaderMessage",
            value: "Keep this screen open while the card reader gets ready.",
            comment: "Message shown while preparing a card reader for an in-person refund."
        )

        static let readerErrorTitle = NSLocalizedString(
            "pos.refundConfirmationView.readerErrorTitle",
            value: "Refund failed",
            comment: "Title shown when an in-person refund fails."
        )

        static let confirmButton = NSLocalizedString(
            "pos.refundConfirmationView.confirmButton",
            value: "Yes, proceed",
            comment: "Button to confirm and process the refund"
        )

        static let backButton = NSLocalizedString(
            "pos.refundConfirmationView.backButton",
            value: "Back",
            comment: "Button to go back to the previous screen"
        )
    }
}

#if DEBUG
#Preview("POSRefundConfirmationView") {
    POSRefundConfirmationView(
        formattedRefundTotal: "$132.60",
        paymentMethodDescription: "via payment card ••••1456",
        isProcessing: false,
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("POSRefundConfirmationView - Processing") {
    POSRefundConfirmationView(
        formattedRefundTotal: "$132.60",
        paymentMethodDescription: "via payment card ••••1456",
        isProcessing: true,
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
