import Foundation

/// Extension to provide fallbacks to new Order properties.
///
internal extension Order {

    // MARK: WC 6.6 properties

    /// Conditions copied from:
    /// https://github.com/woocommerce/woocommerce/blob/3611d4643791bad87a0d3e6e73e031bb80447417/plugins/woocommerce/includes/class-wc-order.php#L1520-L1523
    ///
    static func inferNeedsPayment(status: OrderStatusEnum, total: String) -> Bool {
        guard let total = Double(total) else {
            return false
        }
        return total > .zero && (status == .pending || status == .failed)
    }

    /// Conditions copied from:
    /// https://github.com/woocommerce/woocommerce/blob/3611d4643791bad87a0d3e6e73e031bb80447417/plugins/woocommerce/includes/class-wc-order.php#L1395-L1402
    ///
    static func inferIsEditable(status: OrderStatusEnum) -> Bool {
        return status == .pending || status == .onHold || status == .autoDraft
    }

    /// Temporary. Conditions to be copied from:
    /// https://github.com/woocommerce/woocommerce/blob/3611d4643791bad87a0d3e6e73e031bb80447417/plugins/woocommerce/includes/class-wc-order.php#L1537-L1567
    ///
    static func inferNeedsProcessing(status: OrderStatusEnum) -> Bool {
        return status == .processing
    }
}
