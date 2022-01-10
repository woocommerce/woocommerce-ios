import Foundation

/// Stripe (Extension): Remote Endpoints
///
public class StripeRemote: Remote {
    /// Loads a card reader connection token for a given site ID and parses the response
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the connection token.
    ///   - completion: Closure to be executed upon completion.
    public func loadConnectionToken(for siteID: Int64,
                                    completion: @escaping(Result<ReaderConnectionToken, Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: Path.connectionTokens)

        let mapper = ReaderConnectionTokenMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Loads a Stripe account for a given site ID and parses the response
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the Stripe account info.
    ///   - completion: Closure to be executed upon completion.
    public func loadAccount(for siteID: Int64,
                            completion: @escaping (Result<StripeAccount, Error>) -> Void) {
        let parameters = [AccountParameterKeys.fields: AccountParameterValues.fieldValues]

        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: Path.accounts, parameters: parameters)

        let mapper = StripeAccountMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// TODO loadConnectionToken(for siteID: Int64,...)

    /// TODO captureOrderPayment(for siteID: Int64,...)

    /// Creates a (or returns an existing) Stripe Connect customer for an order. See https://stripe.com/docs/api/customers/create
    /// Updates the order meta with the Customer for us.
    /// Also note that the JSON returned by the WCPay endpoint is an abridged copy of Stripe's response.
    /// - Parameters:
    ///   - siteID: Site for which we'll create (or simply return) the customer.
    ///   - orderID: Order for which we'll create (or simply return) the customer.
    ///   - completion: Closure to be run on completion.
    public func fetchOrderCustomer(for siteID: Int64,
                               orderID: Int64,
                               completion: @escaping (Result<Customer, Error>) -> Void) {
        let path = "\(Path.orders)/\(orderID)/\(Path.createCustomer)"

        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: [:])

        let mapper = WCPayCustomerMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// TODO loadDefaultReaderLocation(for siteID: Int64,...)
}

// MARK: - Constants!
//
private extension StripeRemote {
    enum Path {
        static let connectionTokens = "wc_stripe/connection_tokens"
        static let accounts = "wc_stripe/account/summary"
        static let orders = "payments/orders"
        static let createCustomer = "create_customer"
    }

    enum AccountParameterKeys {
        static let fields: String = "_fields"
    }

    enum AccountParameterValues {
        static let fieldValues: String = """
            status,is_live,test_mode,has_pending_requirements,has_overdue_requirements,current_deadline,\
            statement_descriptor,store_currencies,country
            """
    }
}
