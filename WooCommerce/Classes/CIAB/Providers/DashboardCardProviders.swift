/// Dashboard card availability for standard (non-CIAB) sites.
///
struct StandardDashboardCardProvider: DashboardCardProviding {
    let isStockCardEnabled = true
    let isStoreSetupCardEnabled = true
}

/// Dashboard card availability for CIAB sites.
///
struct CIABDashboardCardProvider: DashboardCardProviding {
    let isStockCardEnabled = false
    let isStoreSetupCardEnabled = false
}
