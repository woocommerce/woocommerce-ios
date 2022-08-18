import Foundation

/// Payment Gateways Endpoints
///
public class PaymentGatewayRemote: Remote {

    /// Retrieves all of the `PaymentGateways` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote payment gateways.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllPaymentGateways(siteID: Int64, completion: @escaping (Result<[PaymentGateway], Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: Constants.path)
        let mapper = PaymentGatewayListMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    // MARK: - Update Payment Gateway

    /// Updates a `PaymentGateway`.
    ///
    /// - Parameters:
    ///     - paymentGateway: The Payment Gateway to be updated remotely.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updatePaymentGateway(_ paymentGateway: PaymentGateway,
                             completion: @escaping (Result<PaymentGateway, Error>) -> Void) {
        do {
            let parameters = try paymentGateway.toDictionary(keyEncodingStrategy: .convertToSnakeCase)
            let siteID = paymentGateway.siteID
            let path = Constants.path + "/\(paymentGateway.gatewayID)"

            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .put,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters)

            let mapper = PaymentGatewayMapper(siteID: siteID)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: Constant
private extension PaymentGatewayRemote {
    enum Constants {
        static let path = "payment_gateways"
    }
}
