/// Order status editing for standard (non-CIAB) sites.
///
struct StandardOrderStatusEditingProvider: OrderStatusEditingProviding {
    let isOrderStatusEditingEnabled = true
}

/// Order status editing for CIAB sites.
///
struct CIABOrderStatusEditingProvider: OrderStatusEditingProviding {
    let isOrderStatusEditingEnabled = false
}
