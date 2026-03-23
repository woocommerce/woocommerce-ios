import Yosemite

/// Determines how a product should be displayed based on the site type.
///
/// Standard sites always show native detail views. CIAB sites route booking
/// products to a web view.
///
protocol ProductRoutingProviding {
    func navigationTarget(for productType: ProductType) -> ProductNavigationTarget
}

/// The possible destinations when navigating to a product detail.
///
enum ProductNavigationTarget {
    case nativeDetail
    case webView
}
