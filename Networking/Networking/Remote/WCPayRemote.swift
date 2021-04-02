import Foundation

/// WCPay: Remote Endpoints
///
public class WCPayRemote: Remote {

    /// Loads a WCPay connection token for a given site ID and parses the rsponse
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the WCPay Connection token.
    ///   - completion: Closure to be executed upon completion.
    public func loadConnectionToken(for siteID: Int64,
                                    completion: @escaping(WCPayConnectionToken?, Error?) -> Void) {
        let path = "payments/connection_tokens"

        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path)

        let mapper = WCPayConnectionTokenMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Loads a WCPay account for a given site ID and parses the rsponse
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the WCPay account info.
    ///   - completion: Closure to be executed upon completion.
    public func loadAccount(for siteID: Int64,
                            completion: @escaping (Result<WCPayAccount, Error>) -> Void) {
        let path = "payments/accounts"

        let parameters = [AccountParameterKeys.fields: AccountParameterValues.fieldValues]

        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)

        let mapper = WCPayAccountMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - Constants!
//
private extension WCPayRemote {

    enum AccountParameterKeys {
        static let fields: String = "_fields"
    }

    enum AccountParameterValues {
        static let fieldValues: String = """
            status,has_pending_requirements,has_overdue_requirements,current_deadline,\
            statement_descriptor,store_currencies,country
            """
    }
}
