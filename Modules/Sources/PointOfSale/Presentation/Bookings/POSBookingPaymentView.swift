// POSBookingPaymentView.swift
import SwiftUI

struct POSBookingPaymentView: View {
    @Environment(POSBookingPaymentController.self) private var controller
    @Environment(\.posAnalytics) private var analytics

    let onDismiss: () -> Void
    let onEmailReceipt: () -> Void

    var body: some View {
        @Bindable var controller = controller  // Local bindable for $ bindings

        ZStack {
            // Show inline message from facade (handles its own layout)
            if let inlineMessage = controller.cardPresentPaymentInlineMessage {
                PointOfSaleCardPresentPaymentInLineMessage(messageType: inlineMessage)
            } else {
                // Fall back to our status content with action buttons
                VStack(spacing: POSSpacing.xxLarge) {
                    Spacer()
                    statusContent
                    Spacer()
                    actionButtons
                }
                .padding(POSSpacing.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(controller.showsPrimaryBackground ? Color.posPrimary : Color.posSurface)
        .animation(.easeInOut, value: controller.showsPrimaryBackground)
        .posModal(item: $controller.cardPresentPaymentAlertViewModel,
                  onDismiss: {
            controller.cardPresentPaymentAlertViewModel?.onDismiss?()
        }) { alertType in
            PointOfSaleCardPresentPaymentAlert(alertType: alertType)
                .posInteractiveDismissDisabled(alertType.isDismissDisabled)
        }
        .onDisappear {
            controller.cancelPendingOperations()
        }
    }

    @ViewBuilder
    private var statusContent: some View {
        switch controller.paymentState {
        case .ready:
            readyContent
        case .processing:
            processingContent
        case .success:
            successContent
        case .error(let message):
            errorContent(message)
        }
    }

    @ViewBuilder
    private var readyContent: some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 64))
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(Localization.tapInsertSwipe)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)

            Text(controller.booking.amount)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.posOnSurface)
        }
    }

    @ViewBuilder
    private var processingContent: some View {
        // Match the style of PointOfSaleCardPresentPaymentProcessingMessageView
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing) {
            ProgressView()
                .progressViewStyle(CardWaveProgressViewStyle())

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(Localization.processing)
                    .foregroundStyle(Color.posOnPrimaryContainer)
                    .font(.posBodyLargeRegular())

                Text(controller.booking.amount)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnPrimaryContainer)
            }
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var successContent: some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.posSuccess)

            Text(Localization.paymentSuccessful)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)

            Text(controller.booking.amount)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.posOnSurface)
        }
    }

    @ViewBuilder
    private func errorContent(_ message: String) -> some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.posError)

            Text(Localization.paymentFailed)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)

            Text(message)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch controller.paymentState {
        case .ready:
            Button(Localization.cancel) {
                Task {
                    try? await controller.cancelPayment()
                    onDismiss()
                }
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))

        case .processing:
            Button(Localization.cancel) {
                Task {
                    try? await controller.cancelPayment()
                    onDismiss()
                }
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))

        case .success:
            VStack(spacing: POSSpacing.medium) {
                Button(Localization.emailReceipt) {
                    onEmailReceipt()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))

                Button(Localization.done) {
                    onDismiss()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
            }

        case .error:
            VStack(spacing: POSSpacing.medium) {
                Button(Localization.tryAgain) {
                    controller.reset()
                    Task {
                        try? await controller.collectCardPayment()
                    }
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                Button(Localization.cancel) {
                    onDismiss()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }
        }
    }

    private enum Localization {
        static let tapInsertSwipe = NSLocalizedString("posBookingPayment.tapInsertSwipe", value: "Tap, insert, or swipe card", comment: "Card reader instruction")
        static let processing = NSLocalizedString("posBookingPayment.processing", value: "Processing payment...", comment: "Payment processing message")
        static let paymentSuccessful = NSLocalizedString("posBookingPayment.success", value: "Payment Successful", comment: "Payment success message")
        static let paymentFailed = NSLocalizedString("posBookingPayment.failed", value: "Payment Failed", comment: "Payment failure message")
        static let cancel = NSLocalizedString("posBookingPayment.cancel", value: "Cancel", comment: "Cancel button")
        static let done = NSLocalizedString("posBookingPayment.done", value: "Done", comment: "Done button")
        static let tryAgain = NSLocalizedString("posBookingPayment.tryAgain", value: "Try Again", comment: "Try again button")
        static let emailReceipt = NSLocalizedString("posBookingPayment.emailReceipt", value: "Email Receipt", comment: "Email receipt button")
    }
}
