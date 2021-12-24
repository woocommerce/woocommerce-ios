/// A PaymentIntent tracks the process of collecting a payment from your customer.
/// We would create exactly one PaymentIntent for each order
public struct PaymentIntent: Identifiable {
    /// Unique identifier for the PaymentIntent
    public let id: String

    /// The status of the Payment Intent
    public let status: PaymentIntentStatus

    /// When the PaymentIntent was created
    public let created: Date

    ///The amount to be collected by this PaymentIntent, provided in the currency’s smallest unit.
    /// e.g. USD$5.00 should have amount = 500 and currency = 'usd'
    /// - see: https://stripe.com/docs/currencies#zero-decimal
    public let amount: UInt

    /// The currency of the payment.
    public let currency: String

    /// Set of key-value pairs attached to the object.
    public let metadata: [String: String]?

    // Charges that were created by this PaymentIntent, if any.
    public let charges: [Charge]
}


public extension PaymentIntent {
    /// Metadata Keys
    enum MetadataKeys {
        public static let store = "paymentintent.storename"

        /// The customer's name - first name then last name separated by a space, or
        /// empty if neither first name nor last name is given.
        /// This key is also used by the plugin when it creates payment intents.
        ///
        public static let customerName = "customer_name"

        /// The customer's email address, or empty if not given.
        /// This key is also used by the plugin when it creates payment intents.
        ///
        public static let customerEmail = "customer_email"

        /// The store URL, e.g. `https://mydomain.com`
        /// This key is also used by the plugin when it creates payment intents.
        ///
        public static let siteURL = "site_url"

        /// The order ID, e.g. 6140
        /// This key is also used by the plugin when it creates payment intents.
        ///
        public static let orderID = "order_id"

        /// The order key, e.g. `wc_order_0000000000000`
        /// This key is also used by the plugin when it creates payment intents.
        ///
        public static let orderKey = "order_key"

        /// The payment type, i.e. `single` or `recurring`
        /// See also PaymentIntent.PaymentTypes
        /// This key is also used by the plugin when it creates payment intents.
        ///
        public static let paymentType = "payment_type"
    }
}

public extension PaymentIntent {
    enum PaymentTypes: String {
        /// A payment that IS NOT associated with an order containing a subscription
        /// This key is also used by the plugin when it creates payment intents.
        ///
        case single = "single"

        /// A payment that IS associated with an order containing a subscription
        /// This key is also used by the plugin when it creates payment intents.
        ///
        case recurring = "recurring"
    }
}

// MARK: - Convenience Initializers
//
public extension PaymentIntent {
    static func initMetadata(store: String? = nil,
                          customerName: String? = nil,
                          customerEmail: String? = nil,
                          siteURL: String? = nil,
                          orderID: Int64? = nil,
                          orderKey: String? = nil,
                          paymentType: PaymentTypes? = nil
    ) -> [String: String] {
        var metadata = [String: String]()

        metadata[PaymentIntent.MetadataKeys.store] = store
        metadata[PaymentIntent.MetadataKeys.customerName] = customerName
        metadata[PaymentIntent.MetadataKeys.customerEmail] = customerEmail
        metadata[PaymentIntent.MetadataKeys.siteURL] = siteURL
        if let orderID = orderID {
            metadata[PaymentIntent.MetadataKeys.orderID] = String(orderID)
        }
        metadata[PaymentIntent.MetadataKeys.orderKey] = orderKey
        metadata[PaymentIntent.MetadataKeys.paymentType] = paymentType?.rawValue

        return metadata
    }
}
