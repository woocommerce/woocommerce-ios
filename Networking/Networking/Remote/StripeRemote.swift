import Foundation

/// Stripe (Extension): Remote Endpoints
///
public class StripeRemote: Remote {
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

    /// TODO fetchOrderCustomer(for siteID: Int64,...)

    /// TODO loadDefaultReaderLocation(for siteID: Int64,...)
}

// MARK: - Constants!
//
private extension StripeRemote {
    enum Path {
        static let accounts = "wc_stripe/account/summary"
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
