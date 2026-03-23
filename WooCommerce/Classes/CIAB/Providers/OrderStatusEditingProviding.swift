/// Provides whether manual order status editing is available on the current site.
///
/// Standard sites allow it; CIAB sites do not.
///
protocol OrderStatusEditingProviding {
    var isOrderStatusEditingEnabled: Bool { get }
}
