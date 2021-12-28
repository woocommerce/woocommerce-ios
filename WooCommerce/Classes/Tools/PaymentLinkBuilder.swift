import Foundation

/// Build a payment link for an order using the following format.
/// `{:store_address}/checkout/{:payment_page_path}/{:order_id}/?pay_for_order=true&key={:order_key}`
///
struct PaymentLinkBuilder {
    /// Default site url.
    ///
    let host: String

    /// Order ID to pay
    let orderID: Int64

    /// Order Key that allows the payment
    ///
    let orderKey: String

    /// Stores custom payment page path
    ///
    let paymentPagePath: String

    /// Assembles the payment link with the provided values
    ///
    func build() -> String {
        "\(host)/checkout/\(paymentPagePath)/\(orderID)/?pay_for_order=true&key=\(orderKey)"
    }
}
