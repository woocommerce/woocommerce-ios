import Yosemite

extension Collection where Iterator.Element == ShippingLabel {
    /// Returns a collection of non-refunded shipping labels.
    var nonRefunded: [Element] {
        self.filter { $0.refund == nil }
    }
}
