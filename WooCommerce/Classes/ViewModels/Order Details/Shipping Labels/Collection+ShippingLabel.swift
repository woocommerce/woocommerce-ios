import Yosemite

extension Collection where Iterator.Element == ShippingLabel {
    /// Returns a collection of non-refunded shipping labels.
    var nonRefunded: [Element] {
        filter { $0.refund == nil }
    }
}
