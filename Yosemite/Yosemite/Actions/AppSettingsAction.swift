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

    /// Sets whether a stats version banner should be shown
    ///
    case setStatsVersionBannerVisibility(banner: StatsVersionBannerVisibility.StatsVersionBanner, shouldShowBanner: Bool)

    /// Sets the last shown stats version associated with the `siteID`
    ///
    case setStatsVersionLastShown(siteID: Int64,
        statsVersion: StatsVersion)

    /// Loads the user preferred Product feature switch given the latest app settings
    ///
    case loadProductsFeatureSwitch(onCompletion: (Bool) -> Void)

    /// Sets the user preferred Product feature switch
    /// If on, Products M2 features are available
    ///
    case setProductsFeatureSwitch(isEnabled: Bool, onCompletion: () -> Void)

    /// Clears all the states related to stats version
    ///
    case resetStatsVersionStates

    // MARK: - General App Settings

    /// Saves the `date` as the last known date that the app was installed. This does not do
    /// anything if there is a persisted installation date already and it is older than the
    /// given `date`.
    ///
    /// - Parameter onCompletion: The `Result`'s success value will be `true` if the installation
    ///                           date was changed and `false` if not.
    ///
    case setInstallationDateIfNecessary(date: Date, onCompletion: ((Result<Bool, Error>) -> Void))

    /// Saves the `date` as the last known date that the user interacted with the in-app
    /// feedback prompt (https://git.io/JJ8i0).
    ///
    case setLastFeedbackDate(date: Date, onCompletion: ((Result<Void, Error>) -> Void))
}
