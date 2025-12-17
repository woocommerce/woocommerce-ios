import Foundation

/// Represents the response from a WooCommerce Store API checkout request.
///
public struct StoreAPICheckoutResponse: Decodable, Equatable {
    /// The created order ID.
    public let orderID: Int64

    /// Order status (e.g., "pending", "completed").
    public let status: String

    /// Unique key for the order.
    public let orderKey: String

    /// Customer ID (0 for guest).
    public let customerID: Int64

    /// Payment result information.
    public let paymentResult: StoreAPIPaymentResult

    public init(
        orderID: Int64,
        status: String,
        orderKey: String,
        customerID: Int64,
        paymentResult: StoreAPIPaymentResult
    ) {
        self.orderID = orderID
        self.status = status
        self.orderKey = orderKey
        self.customerID = customerID
        self.paymentResult = paymentResult
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        orderID = try container.decode(Int64.self, forKey: .orderID)
        status = try container.decode(String.self, forKey: .status)
        orderKey = try container.decodeIfPresent(String.self, forKey: .orderKey) ?? ""
        customerID = try container.decodeIfPresent(Int64.self, forKey: .customerID) ?? 0
        paymentResult = try container.decode(StoreAPIPaymentResult.self, forKey: .paymentResult)
    }
}

private extension StoreAPICheckoutResponse {
    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case status
        case orderKey = "order_key"
        case customerID = "customer_id"
        case paymentResult = "payment_result"
    }
}

// MARK: - Payment Result

/// Payment result from a Store API checkout.
///
public struct StoreAPIPaymentResult: Decodable, Equatable {
    /// Payment status (e.g., "success", "pending", "failure").
    public let paymentStatus: String

    /// Details about the payment result.
    public let paymentDetails: [StoreAPIPaymentDetail]

    /// URL to redirect the customer to (if applicable).
    public let redirectURL: String

    public init(
        paymentStatus: String,
        paymentDetails: [StoreAPIPaymentDetail],
        redirectURL: String
    ) {
        self.paymentStatus = paymentStatus
        self.paymentDetails = paymentDetails
        self.redirectURL = redirectURL
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        paymentStatus = try container.decode(String.self, forKey: .paymentStatus)
        paymentDetails = try container.decodeIfPresent([StoreAPIPaymentDetail].self, forKey: .paymentDetails) ?? []
        redirectURL = try container.decodeIfPresent(String.self, forKey: .redirectURL) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case paymentStatus = "payment_status"
        case paymentDetails = "payment_details"
        case redirectURL = "redirect_url"
    }
}

// MARK: - Payment Detail

/// A key-value detail from the payment result.
///
public struct StoreAPIPaymentDetail: Decodable, Equatable {
    /// Detail key.
    public let key: String

    /// Detail value.
    public let value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
