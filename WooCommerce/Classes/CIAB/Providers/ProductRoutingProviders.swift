import Yosemite

/// Product routing for standard (non-CIAB) sites.
///
/// All products are shown via native detail views.
///
struct StandardProductRoutingProvider: ProductRoutingProviding {
    func navigationTarget(for productType: ProductType) -> ProductNavigationTarget {
        .nativeDetail
    }
}

/// Product routing for CIAB sites.
///
/// Booking products are routed to a web view; all others use native detail.
///
struct CIABProductRoutingProvider: ProductRoutingProviding {
    func navigationTarget(for productType: ProductType) -> ProductNavigationTarget {
        productType == .booking ? .webView : .nativeDetail
    }
}
