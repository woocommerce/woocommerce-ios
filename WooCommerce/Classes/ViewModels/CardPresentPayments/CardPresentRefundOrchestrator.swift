import Yosemite
import PassKit

/// Orchestrates the sequence of actions required to refund in-person that is required for certain payment methods:
/// 1. Check if there is a card reader connected
/// 2. Launch the reader discovering and pairing UI if there is no reader connected
/// 3. Refund payment in-person with a card reader.
/// Steps 1 and 2 are the same as the payments flow in `PaymentCaptureOrchestrator`.
final class CardPresentRefundOrchestrator {
    private let stores: StoresManager
    private var walletSuppressionRequestToken: PKSuppressionRequestToken?

    init(stores: StoresManager) {
        self.stores = stores
    }

    /// Refunds a payment for an order in-person, which is required for certain payment methods like Interac in Canada.
    /// - Parameters:
    ///   - amount: the amount to refund in Decimal.
    ///   - charge: details about how the order was charged to verify refund.
    ///   - paymentGatewayAccount: payment gateway (e.g. WCPay or Stripe extension).
    ///   - onWaitingForInput: called when the card reader is waiting for card input.
    ///   - onProcessingMessage: called when the refund is processing.
    ///   - onDisplayMessage: called when the card reader sends a message to display to the user.
    ///   - onCompletion: called when the refund completes.
    func refund(amount: Decimal,
                charge: WCPayCharge,
                paymentGatewayAccount: PaymentGatewayAccount,
                onWaitingForInput: @escaping () -> Void,
                onProcessingMessage: @escaping () -> Void,
                onDisplayMessage: @escaping (String) -> Void,
                onCompletion: @escaping (Result<Void, Error>) -> Void) {
        /// Sets the state of `CardPresentPaymentStore`.
        let setAccount = CardPresentPaymentAction.use(paymentGatewayAccount: paymentGatewayAccount)
        stores.dispatch(setAccount)

        /// Briefly suppresses pass (wallet) presentation so that the merchant doesn't attempt to pay for the buyer's order when the
        /// reader begins to collect payment.
        suppressPassPresentation()

        /// Refunds payment in-person with a card reader.
        let refundParameters = RefundParameters(chargeId: charge.id, amount: amount, currency: charge.currency)
        let refundAction = CardPresentPaymentAction.refundPayment(parameters: refundParameters,
                                                                  onCardReaderMessage: { event in
            switch event {
            case .waitingForInput:
                onWaitingForInput()
            case .displayMessage(let message):
                onDisplayMessage(message)
            default:
                break
            }
        }, onCompletion: { result in
            onCompletion(result)
        })
        stores.dispatch(refundAction)
    }

    /// Cancels the current refund.
    /// - Parameter onCompletion: called when the cancellation completes.
    func cancelRefund(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = CardPresentPaymentAction.cancelRefund() { [weak self] result in
            self?.allowPassPresentation()
            onCompletion(result)
        }
        stores.dispatch(action)
    }
}

// MARK: - Apple wallet suppression

private extension CardPresentRefundOrchestrator {
    /// Suppresses wallet presentation. This requires a special entitlement from Apple:
    /// `com.apple.developer.passkit.pass-presentation-suppression`
    /// See Woo-*.entitlements in WooCommerce/Resources
    func suppressPassPresentation() {
        /// iPads don't support NFC passes. Attempting to call `requestAutomaticPassPresentationSuppression` on them will
        /// return 0 `notSupported`
        ///
        guard !UIDevice.isPad() else {
            return
        }

        guard !PKPassLibrary.isSuppressingAutomaticPassPresentation() else {
            return
        }

        walletSuppressionRequestToken = PKPassLibrary.requestAutomaticPassPresentationSuppression() { result in
            guard result == .success else {
                DDLogWarn("Automatic pass presentation suppression request failed. Reason: \(result.rawValue)")

                let logProperties: [String: Any] = ["PKAutomaticPassPresentationSuppressionResult": result.rawValue]
                ServiceLocator.crashLogging.logMessage(
                    "Automatic pass presentation suppression request failed",
                    properties: logProperties,
                    level: .warning
                )
                return
            }
        }
    }

    /// Restores wallet presentation.
    func allowPassPresentation() {
        /// iPads don't have passes (wallets) to present
        ///
        guard !UIDevice.isPad() else {
            return
        }

        guard let walletSuppressionRequestToken = walletSuppressionRequestToken, walletSuppressionRequestToken != 0 else {
            return
        }

        PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: walletSuppressionRequestToken)
    }
}
