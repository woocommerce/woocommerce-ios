#if os(iOS)

import Combine
import Foundation

/// WCPay: Remote Endpoints
///
public class WCPayRemote: Remote {
    /// Loads a WCPay account for a given site ID and parses the response
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the WCPay account info.
    ///   - completion: Closure to be executed upon completion.
    public func loadAccount(for siteID: Int64,
                            completion: @escaping (Result<WCPayAccount, Error>) -> Void) {
        let parameters = [AccountParameterKeys.fields: AccountParameterValues.fieldValues]

        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.accounts,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)

        let mapper = WCPayAccountMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Captures a payment for an order and returns a publisher of the result. See https://stripe.com/docs/terminal/payments#capture-payment
    /// - Parameters:
    ///   - siteID: Site for which we'll capture the payment.
    ///   - orderID: Order for which we are capturing the payment.
    ///   - paymentIntentID: Stripe Payment Intent ID created using the Terminal SDK.
    public func captureOrderPayment(for siteID: Int64,
                                    orderID: Int64,
                                    paymentIntentID: String) -> AnyPublisher<Result<RemotePaymentIntent, Error>, Never> {
        let path = "\(Path.orders)/\(orderID)/\(Path.captureTerminalPayment)"

        let parameters = [
            CaptureOrderPaymentKeys.fields: CaptureOrderPaymentValues.fieldValues,
            CaptureOrderPaymentKeys.paymentIntentID: paymentIntentID
        ]

        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)

        let mapper = RemotePaymentIntentMapper()

        return enqueue(request, mapper: mapper)
    }

    /// Fetches the details of a charge, if available. See https://stripe.com/docs/api/charges/object
    /// Also note that the JSON returned by the WCPay endpoint is an abridged copy of Stripe's response.
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the charge.
    ///   - chargeID: ID of the charge to fetch
    ///   - completion: Closure to be run on completion.
    public func fetchCharge(for siteID: Int64,
                            chargeID: String,
                            completion: @escaping (Result<WCPayCharge, Error>) -> Void) {
        let path = "\(Path.charges)/\(chargeID)"

        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: [:],
                                     availableAsRESTRequest: true)

        let mapper = WCPayChargeMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - CardReaderCapableRemote
//
extension WCPayRemote {
    /// Loads a card reader connection token for a given site ID and parses the response
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the connection token.
    ///   - completion: Closure to be executed upon completion.
    public func loadConnectionToken(for siteID: Int64,
                                    completion: @escaping(Result<ReaderConnectionToken, Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: Path.connectionTokens,
                                     availableAsRESTRequest: true)

        let mapper = ReaderConnectionTokenMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Load the store's location for use as a default location for a card reader
    /// The backend (since WCPay plugin 3.0.0) coordinates this with Stripe to return a proper Stripe Location object ID
    ///- Parameters:
    ///   - siteID: Site for which we'll fetch the location.
    ///   - completion: Closure to be run on completion.
    ///
    public func loadDefaultReaderLocation(for siteID: Int64,
                                          onCompletion: @escaping (Result<RemoteReaderLocation, Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.locations,
                                     parameters: [:],
                                     availableAsRESTRequest: true)

        let mapper = RemoteReaderLocationMapper()

        enqueue(request, mapper: mapper, completion: onCompletion)
    }
}

// MARK: - Deposits
//
extension WCPayRemote {
    public func loadDepositsOverview(for siteID: Int64) async throws -> WooPaymentsDepositsOverview {
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.depositsOverview,
                                     availableAsRESTRequest: true)

        let mapper = WooPaymentsDepositsOverviewMapper()

        return try await enqueue(request, mapper: mapper)
    }
}

// MARK: - Constants!
//
private extension WCPayRemote {
    enum Path {
        static let connectionTokens = "payments/connection_tokens"
        static let accounts = "payments/accounts"
        static let orders = "payments/orders"
        static let captureTerminalPayment = "capture_terminal_payment"
        static let createCustomer = "create_customer"
        static let locations = "payments/terminal/locations/store"
        static let charges = "payments/charges"
        static let depositsOverview = "payments/deposits/overview-all"
    }

    enum AccountParameterKeys {
        static let fields: String = "_fields"
    }

    enum AccountParameterValues {
        static let fieldValues: String = """
            status,is_live,test_mode,has_pending_requirements,has_overdue_requirements,current_deadline,\
            statement_descriptor,store_currencies,country,card_present_eligible
            """
    }

    enum CaptureOrderPaymentKeys {
        static let fields: String = "_fields"
        static let paymentIntentID: String = "payment_intent_id"
    }

    enum CaptureOrderPaymentValues {
        static let fieldValues: String = "id,status"
    }
}

#endif
