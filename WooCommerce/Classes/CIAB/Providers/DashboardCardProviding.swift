/// Provides dashboard card availability for the current site type.
///
/// Standard sites show stock and store setup cards; CIAB sites do not.
///
protocol DashboardCardProviding {
    var isStockCardEnabled: Bool { get }
    var isStoreSetupCardEnabled: Bool { get }
}
