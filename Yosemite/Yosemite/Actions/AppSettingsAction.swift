import Foundation
import Storage

// MARK: - AppSettingsAction: Defines all of the Actions supported by the AppSettingsStore.
//
public enum AppSettingsAction: Action {
    /// Adds a shipment tracking provider with `providerName` associated with the `siteID`
    ///
    case addTrackingProvider(siteID: Int64,
        providerName: String,
        onCompletion: (Error?) -> Void)

    /// Loads the stored shipment tracking provider associated with the `siteID`
    ///
    case loadTrackingProvider(siteID: Int64,
        onCompletion: (ShipmentTrackingProvider?, ShipmentTrackingProviderGroup?, Error?) -> Void)

    /// Adds a custom shipment tracking provider with `providerName` and `providerURL` associated with the `siteID`
    ///
    case addCustomTrackingProvider(siteID: Int64,
        providerName: String,
        providerURL: String?,
        onCompletion: (Error?) -> Void)

    /// Loads the stored shipment tracking provider associated with the `siteID`
    ///
    case loadCustomTrackingProvider(siteID: Int64,
        onCompletion: (ShipmentTrackingProvider?, Error?) -> Void)

    /// Clears the stored providers
    ///
    case resetStoredProviders(onCompletion: ((Error?) -> Void)?)

    // MARK: - Stats version

    /// Loads the stats version to be shown given the latest app settings associated with the `siteID`
    ///
    case loadInitialStatsVersionToShow(siteID: Int64,
        onCompletion: (StatsVersion?) -> Void)

    /// Loads whether a stats verion banner should be shown
    ///
    case loadStatsVersionBannerVisibility(banner: StatsVersionBannerVisibility.StatsVersionBanner, onCompletion: (Bool) -> Void)

    /// Loads the eligible stats version given the latest app settings associated with the `siteID`
    ///
    case loadStatsVersionEligible(siteID: Int64,
        onCompletion: (StatsVersion?) -> Void)

    /// Sets whether a stats version banner should be shown
    ///
    case setStatsVersionBannerVisibility(banner: StatsVersionBannerVisibility.StatsVersionBanner, shouldShowBanner: Bool)

    /// Sets the latest highest eligible stats version associated with the `siteID`
    ///
    case setStatsVersionEligible(siteID: Int64,
        statsVersion: StatsVersion)

    /// Sets the last shown stats version associated with the `siteID`
    ///
    case setStatsVersionLastShown(siteID: Int64,
        statsVersion: StatsVersion)

    /// Sets the user preferred stats version associated with the `siteID`
    ///
    case setStatsVersionPreference(siteID: Int64,
        statsVersion: StatsVersion)

    /// Loads the user preferred Product Features visibility given the latest app settings
    ///
    case loadProductsVisibility(onCompletion: (Bool) -> Void)

    /// Sets the user preferred Product Features visibility
    ///
    case setProductsVisibility(isVisible: Bool, onCompletion: () -> Void)

    /// Loads the user preferred Edit Products given the latest app settings
    ///
    case loadEditProducts(onCompletion: (Bool) -> Void)

    /// Sets the user preferred Edit Products functionality
    ///
    case setEditProducts(isEnabled: Bool, onCompletion: () -> Void)

    /// Clears all the states related to stats version
    ///
    case resetStatsVersionStates
}
