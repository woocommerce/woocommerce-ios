import Yosemite

extension Order {
    /// Whether the refund should display the order's payment method title rather than "manual refund".
    ///
    /// This is true when either:
    /// - The refund was processed automatically by the payment gateway (`isAutomated`), or
    /// - The order was paid via Cash on Delivery (Pay in Person), where the API always returns
    ///   `refunded_payment: false` because no electronic refund occurs.
    func refundShowsPaymentMethod(_ refund: Refund) -> Bool {
        (refund.isAutomated ?? false) || paymentMethodID == PaymentGateway.Constants.cashOnDeliveryGatewayID
    }
}
