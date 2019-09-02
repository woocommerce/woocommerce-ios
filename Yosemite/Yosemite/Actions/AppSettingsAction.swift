import Foundation
import Storage

// MARK: - AppSettingsAction: Defines all of the Actions supported by the AppSettingsStore.
//
public enum AppSettingsAction: Action {
    /// Adds a shipment tracking provider with `providerName` associated with the `siteID`
    ///
    case addTrackingProvider(siteID: Int,
        providerName: String,
        onCompletion: (Error?) -> Void)

    /// Loads the stored shipment tracking provider associated with the `siteID`
    ///
    case loadTrackingProvider(siteID: Int,
        onCompletion: (ShipmentTrackingProvider?, ShipmentTrackingProviderGroup?, Error?) -> Void)

    /// Adds a custom shipment tracking provider with `providerName` and `providerURL` associated with the `siteID`
    ///
    case addCustomTrackingProvider(siteID: Int,
        providerName: String,
        providerURL: String?,
        onCompletion: (Error?) -> Void)

    /// Loads the stored shipment tracking provider associated with the `siteID`
    ///
    case loadCustomTrackingProvider(siteID: Int,
        onCompletion: (ShipmentTrackingProvider?, Error?) -> Void)

    /// Clears the stored providers
    ///
    case resetStoredProviders(onCompletion: ((Error?) -> Void)?)

    // MARK: - Stats version

    /// Loads the stats version to be shown given the latest app settings associated with the `siteID`
    ///
    case loadInitialStatsVersionToShow(siteID: Int,
        onCompletion: (StatsVersion?) -> Void)

    /// Loads whether stats v3 to v4 banner should be shown
    ///
    case loadStatsV3ToV4BannerVisibility(onCompletion: (Bool) -> Void)

    /// Loads whether stats v4 to v3 banner should be shown
    ///
    case loadStatsV4ToV3BannerVisibility(onCompletion: (Bool) -> Void)

    /// Loads the eligible stats version given the latest app settings associated with the `siteID`
    ///
    case loadStatsVersionEligible(siteID: Int,
        onCompletion: (StatsVersion?) -> Void)

    /// Sets the last shown stats version associated with the `siteID`
    ///
    case setStatsVersionLastShown(siteID: Int,
        statsVersion: StatsVersion)
    
    /// Sets the latest highest eligible stats version associated with the `siteID`
    ///
    case setStatsVersionEligible(siteID: Int,
        statsVersion: StatsVersion)
    
    /// Sets the user preferred stats version associated with the `siteID`
    ///
    case setStatsVersionPreference(siteID: Int,
        statsVersion: StatsVersion)
    
    /// Sets whether stats v3 to v4 banner should be shown
    ///
    case setStatsV3ToV4BannerVisibility(shouldShowBanner: Bool)
    
    /// Sets whether stats v4 to v3 banner should be shown
    ///
    case setStatsV4ToV3BannerVisibility(shouldShowBanner: Bool)

    /// Clears all the states related to stats version
    ///
    case resetStatsVersionStates
}
