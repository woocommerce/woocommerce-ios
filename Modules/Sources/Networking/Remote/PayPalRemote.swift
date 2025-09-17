import Combine
import Foundation

/// PayPal: Remote Endpoints for card present payments
///
public class PayPalRemote: Remote {
    
    /// Captures a PayPal payment for an order and returns a publisher of the result
    /// - Parameters:
    ///   - siteID: Site for which we'll capture the payment.
    ///   - orderID: Order for which we are capturing the payment.
    ///   - paymentIntentID: PayPal Payment Intent ID created using the iZettle SDK.
    public func captureOrderPayment(for siteID: Int64,
                                    orderID: Int64,
                                    paymentIntentID: String) -> AnyPublisher<Result<RemotePaymentIntent, Error>, Never> {
        
        // Use same pattern as StripeRemote - call a specific REST endpoint
        let path = "\(Path.orders)/\(orderID)/\(Path.capturePayPalPayment)"

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

        print("💰 [PayPalRemote] Capturing PayPal payment via REST endpoint")
        print("💰 [PayPalRemote] Endpoint: \(path)")
        print("💰 [PayPalRemote] Payment Intent: \(paymentIntentID)")
        
        return enqueue(request, mapper: mapper)
    }
    
    /// Loads a PayPal account for a given site ID and parses the response
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the PayPal account info.
    ///   - completion: Closure to be executed upon completion.
    public func loadAccount(for siteID: Int64,
                            completion: @escaping (Result<PayPalAccount, Error>) -> Void) {
        let parameters = [AccountParameterKeys.fields: AccountParameterValues.fieldValues]

        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.paypalAccounts,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)

        let mapper = PayPalAccountMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
    
    /// Fetch Zettle access token from the PayPal plugin backend
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the token.
    ///   - completion: Closure to be executed upon completion.
    public func fetchZettleAccessToken(for siteID: Int64,
                                       completion: @escaping (Result<ZettleTokenResponse, Error>) -> Void) {
        
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: Path.zettleAccessToken,
                                     availableAsRESTRequest: true)

        let mapper = SingleItemMapper<ZettleTokenResponse>(siteID: siteID)

        print("💳🌐 [PayPalRemote] Fetching Zettle access token from backend")
        
        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - PayPal Constants
private extension PayPalRemote {
    enum Path {
        static let orders = "payments/orders"
        static let capturePayPalPayment = "capture_paypal_payment"
        static let paypalAccounts = "payments/paypal_accounts"
        static let zettleAccessToken = "zettle/access-token"
    }
    
    enum AccountParameterKeys {
        static let fields = "fields"
    }
    
    enum AccountParameterValues {
        static let fieldValues = "status,has_pending_requirements,has_overdue_requirements,current_deadline,is_live"
    }
    
    enum CaptureOrderPaymentKeys {
        static let fields = "fields" 
        static let paymentIntentID = "payment_intent_id"
    }
    
    enum CaptureOrderPaymentValues {
        static let fieldValues = "id,status,created,amount,currency,payment_method,charges"
    }
}

// MARK: - Zettle Token Response Model
public struct ZettleTokenResponse: Codable {
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: Int
    public let refreshToken: String?
    public let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}
