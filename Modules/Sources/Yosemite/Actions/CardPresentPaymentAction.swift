// MARK: - CardPresentPaymentAction: Defines all of the Actions supported by the CardPresentPaymentStore.
//

import Combine
import Foundation
import enum WooFoundation.CountryCode

public enum CardPresentPaymentAction: Action {
    /// Sets the store to use a given payment gateway
    ///
    case use(paymentGatewayAccount: PaymentGatewayAccount)

    /// Returns the selected payment gateway account, set previously with CardPresentPaymentAction.use
    ///
    case selectedPaymentGatewayAccount(onCompletion: (PaymentGatewayAccount?) -> Void)

    /// Retrieves the current configuration for IPP.
    ///
    case loadActivePaymentGatewayExtension(onCompletion: (CardPresentPaymentsPlugin) -> Void)

    /// Retrieves and stores payment gateway account(s) for the provided `siteID`
    /// We support payment gateway accounts for both the WooPayments extension AND
    /// the Stripe extension. Let's attempt to load each and update view storage with the results.
    /// Calls the passed completion with success after both loads have been attempted.
    ///
    case loadAccounts(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)

    case checkDeviceSupport(siteID: Int64,
                            cardReaderType: CardReaderType,
                            discoveryMethod: CardReaderDiscoveryMethod,
                            minimumOperatingSystemVersionOverride: OperatingSystemVersion?,
                            onCompletion: (Bool) -> Void)

    /// Start the Card Reader discovery process.
    ///
    case startCardReaderDiscovery(siteID: Int64,
                                  discoveryMethod: CardReaderDiscoveryMethod,
                                  onReaderDiscovered: ([CardReader]) -> Void,
                                  onError: (Error) -> Void)

    /// Cancels the Card Reader discovery process.
    ///
    case cancelCardReaderDiscovery(onCompletion: (Result<Void, Error>) -> Void)

    /// Connect to a specific CardReader.
    /// Stops Card Reader discovery
    ///
    case connect(reader: CardReader, options: CardReaderConnectionOptions? = nil, onCompletion: (Result<CardReader, Error>) -> Void)

    /// Disconnect from currently connected Reader
    ///
    case disconnect(onCompletion: (Result<Void, Error>) -> Void)

    /// Calls the completion block everytime the list of connected readers changes
    /// with an array of connected readers.
    ///
    case observeConnectedReaders(onCompletion: ([CardReader]) -> Void)

    /// Collected payment for an order.
    ///
    case collectPayment(siteID: Int64,
                        orderID: Int64,
                        parameters: PaymentParameters,
                        countryCode: CountryCode,
                        terminalPaymentPreparationEnabled: Bool,
                        onCardReaderMessage: (CardReaderEvent) -> Void,
                        onProcessingCompletion: (PaymentIntent) -> Void,
                        onCompletion: (Result<PaymentIntent, Error>) -> Void)

    /// Cancels an active attempt to collect a payment.
    case cancelPayment(onCompletion: ((Result<Void, Error>) -> Void)?)

    case retryPayment(siteID: Int64,
                      orderID: Int64,
                      countryCode: CountryCode,
                      terminalPaymentPreparationEnabled: Bool,
                      onCardReaderMessage: (CardReaderEvent) -> Void,
                      onProcessingCompletion: (PaymentIntent) -> Void,
                      onCompletion: (Result<PaymentIntent, Error>) -> Void)

    /// Refund payment of an order, client side. Only for use on Interac payments
    ///
    case refundPayment(parameters: RefundParameters, onCardReaderMessage: (CardReaderEvent) -> Void, onCompletion: ((Result<Void, Error>) -> Void)?)

    /// Cancels a refund, if one is in progress
    case cancelRefund(onCompletion: ((Result<Void, Error>) -> Void)?)

    /// Check the state of available software updates.
    case observeCardReaderUpdateState(onCompletion: (AnyPublisher<CardReaderSoftwareUpdateState, Never>) -> Void)

    /// Observe TTP Terms and Services accept event
    case observeTapToPayCardReaderAcceptToS(onCompletion: (AnyPublisher<Void, Never>) -> Void)

    /// Update card reader firmware.
    case startCardReaderUpdate

    /// Restarts the card present payments system
    /// This might imply, but not be limited to:
    /// 1. Disconnect from a connected reader
    /// 2. Clear all credentials, cached data
    /// 3. Reset all status indicators
    case reset(onCompletion: () -> Void)

    /// Provides a publisher for card reader connections
    case publishCardReaderConnections(onCompletion: (AnyPublisher<[CardReader], Never>) -> Void)

    /// Fetches Charge details by charge ID
    ///
    case fetchWCPayCharge(siteID: Int64, chargeID: String, onCompletion: (Result<WCPayCharge, Error>) -> Void)

    /// Provides a publisher for card reader reconnection state changes.
    /// Used to observe when a Bluetooth card reader is attempting to auto-reconnect.
    case observeCardReaderReconnectionState(onCompletion: (AnyPublisher<CardReaderReconnectionState, Never>) -> Void)

    /// Cancels an in-progress auto-reconnection attempt.
    case cancelReconnection(onCompletion: (Result<Void, Error>) -> Void)
}
