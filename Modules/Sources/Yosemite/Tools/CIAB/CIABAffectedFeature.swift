/// Describes the feature set affected by CIAB sites
/// By the moment of introduction the features aren't supported by CIAB sites

public enum CIABAffectedFeature: CaseIterable {
    case blaze
    case splitShipments
    case groupedProducts
    case variableProducts
    case subscriptionProducts
    case bundleProducts
    case compositeProducts
    case productsStockDashboardCard
    case pointOfSale
    case storeSetupDashboardCard
    case manualOrderStatusUpdate
}

extension CIABAffectedFeature {
    /// Defines a collection of existing app features unsupported in CIAB sites
    /// In case if a certain feature is reconsidered and decided to be supported in CIAB
    /// just remove it from the collection
    static var unsupportedFeatures: [CIABAffectedFeature] {
        /// `.pointOfSale` excluded since POS is revised to be available in CIAB MVP
        return CIABAffectedFeature.allCases.filter { $0 != .pointOfSale }
    }
}
