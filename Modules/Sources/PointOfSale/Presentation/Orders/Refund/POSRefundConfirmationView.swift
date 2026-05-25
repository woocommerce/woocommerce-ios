import SwiftUI

struct POSRefundConfirmationView: View {
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let isProcessing: Bool
    var submissionState: POSRefundSubmissionState = .idle
    let onClose: () -> Void
    let onConfirm: () -> Void
    let onBack: (() -> Void)?

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Namespace private var paymentMessageNamespace

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: POSSpacing.none) {
                if isProcessing {
                    processingSection
                } else {
                    Spacer(minLength: POSSpacing.large)
                    confirmationMessageView
                    Spacer(minLength: POSSpacing.large)
                    buttonsSection
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if shouldShowHeader {
                headerView
            }
        }
        .background(backgroundColor)
        .posRefundModalFrame(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass)
    }
}

// MARK: - Subviews

private extension POSRefundConfirmationView {
    var headerView: some View {
        POSRefundNavigationHeader(backAction: headerBackAction,
                                  backAccessibilityLabel: Localization.backButtonAccessibilityLabel)
    }

    var shouldShowHeader: Bool {
        guard primaryBackgroundCardPresentMessageType == nil else {
            return false
        }

        if isProcessing {
            switch submissionState {
            case .retryableError, .nonRetryableError:
                return false
            case .idle, .loading, .processingReader, .displayingReaderMessage, .submitting, .submittingCardPresent, .completed:
                return false
            case .onboarding, .cardPresentEvent, .preparingReader, .waitingForCard:
                return headerBackAction != nil
            }
        }
        return headerBackAction != nil
    }

    var backgroundColor: Color {
        guard isProcessing else {
            return .posSurfaceBright
        }

        return primaryBackgroundCardPresentMessageType == nil ? Color.posSurfaceBright : Color.posPrimary
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
        case .submittingCardPresent:
            return .processing(.processing)
        }
    }

    var headerBackAction: (() -> Void)? {
        guard isProcessing else {
            return onBack
        }
        return processingCancelAction
    }

    var processingCancelAction: (() -> Void)? {
        switch submissionState {
        case .onboarding(_, let onCancel):
            return cancelAndReturnToConfirmation(onCancel)
        case .cardPresentEvent(let eventDetails):
            return eventDetails.posRefundCancelAction.map(cancelAndReturnToConfirmation)
        case .preparingReader(let cancel),
                .waitingForCard(_, let cancel):
            return cancelAndReturnToConfirmation(cancel)
        case .idle, .loading, .processingReader, .displayingReaderMessage, .submitting, .submittingCardPresent,
                .retryableError, .nonRetryableError, .completed:
            return nil
        }
    }

    func cancelAndReturnToConfirmation(_ cancel: @escaping () -> Void) -> () -> Void {
        {
            onBack?()
            cancel()
        }
    }

    var confirmationMessageView: some View {
        VStack(spacing: POSSpacing.small) {
            Text(String(format: Localization.titleFormat, formattedRefundTotal))
                .font(.posHeadingBold)
                .foregroundColor(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            Text(String(format: Localization.confirmationQuestionFormat,
                        formattedRefundTotal,
                        paymentMethodDescription))
                .font(.posBodyLargeRegular())
                .foregroundColor(Color.posOnSurface)

            Text(Localization.actionCannotBeUndone)
                .font(.posBodyLargeRegular())
                .foregroundColor(Color.posOnSurface)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, POSPadding.xLarge)
        .frame(maxWidth: POSRefundModalLayout.fullScreenContentMaxWidth)
    }

    @ViewBuilder
    var processingSection: some View {
        switch submissionState {
        case .onboarding:
            loadingSection
        case .cardPresentEvent(let eventDetails):
            if let messageType = refundMessageType(for: eventDetails) {
                cardPresentMessageView(messageType)
            } else {
                loadingSection
            }
        case .preparingReader:
            POSPaymentLoadingView(title: Localization.preparingReaderTitle,
                                  message: Localization.preparingReaderMessage,
                                  animation: .init(namespace: paymentMessageNamespace))
            .padding(POSPadding.xLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        case .submittingCardPresent:
            cardPresentMessageView(.processing(.processing))
        case .idle, .loading, .submitting, .completed:
            loadingSection
        }
    }

    var loadingSection: some View {
        POSPaymentLoadingView(title: String(format: Localization.processingTitleFormat, formattedRefundTotal),
                              message: Localization.processingMessage,
                              animation: .init(namespace: paymentMessageNamespace))
        .frame(maxWidth: .infinity)
        .padding(POSPadding.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func cardPresentMessageView(_ messageType: POSRefundCardPresentMessageType) -> some View {
        POSRefundCardPresentMessageView(messageType: messageType,
                                        animation: .init(namespace: paymentMessageNamespace))
        .padding(POSPadding.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        case .paymentSuccess:
            return .processing(.processing)
        case .displayReaderMessage(let message):
            return .displayReaderMessage(.displayReaderMessage(message))
        case .cancelledOnReader:
            return .cancelledOnReader(.cancelledOnReader(backToRefund: onBack ?? onClose))
        case .paymentError(let error, let retryApproach, let cancelPayment):
            return .error(.init(error: error,
                                retryAction: retryAction(for: retryApproach),
                                cancelAction: cancelAndReturnToConfirmation(cancelPayment)))
        case .paymentCaptureError(let cancelPayment):
            return .error(.init(error: POSRefundCardPresentPresentationError.unableToConfirmRefund,
                                retryAction: nil,
                                cancelAction: cancelAndReturnToConfirmation(cancelPayment)))
        case .paymentIntentCreationError(let error, let cancelPayment):
            return .error(.init(error: error,
                                retryAction: nil,
                                cancelAction: cancelAndReturnToConfirmation(cancelPayment)))
        case .scanningForReaders, .scanningFailed, .bluetoothRequired, .connectingToReader, .connectingFailed,
                .connectingFailedNonRetryable, .connectingFailedUpdatePostalCode, .connectingFailedChargeReader,
                .connectingFailedUpdateAddress, .selectSearchType, .foundReader, .foundMultipleReaders, .updateProgress,
                .updateFailed, .updateFailedNonRetryable, .updateFailedLowBattery, .connectionSuccess,
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

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(Localization.confirmButton, action: onConfirm)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.cancelButton, action: onClose)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .posPhoneFullScreenButtonPadding(horizontalSizeClass: horizontalSizeClass,
                                         maxWidth: .infinity)
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

extension CardPresentPaymentEventDetails {
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

        static let backButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundConfirmationView.backButton.accessibilityLabel",
            value: "Back",
            comment: "Accessibility label for the back button on the refund confirmation screen"
        )

        static let confirmationQuestionFormat = NSLocalizedString(
            "pos.refundConfirmationView.confirmationQuestionFormat",
            value: "Are you sure you wish to refund %1$@ %2$@?",
            comment: "Confirmation question for the refund. %1$@ is the formatted amount, %2$@ is the payment method description."
        )

        static let actionCannotBeUndone = NSLocalizedString(
            "pos.refundConfirmationView.actionCannotBeUndone",
            value: "This action cannot be undone.",
            comment: "Warning shown on the refund confirmation screen."
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

        static let cancelButton = NSLocalizedString(
            "pos.refundConfirmationView.cancelButton",
            value: "Cancel",
            comment: "Button to cancel and dismiss the refund confirmation screen"
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
