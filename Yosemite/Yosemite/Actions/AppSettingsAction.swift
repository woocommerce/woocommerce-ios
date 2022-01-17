import Foundation
import Storage
import Networking

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

    /// Clears all the states related to stats version
    ///
    case resetStatsVersionStates

    // MARK: - Orders Settings

    /// Loads the orders settings
    ///
    case loadOrdersSettings(siteID: Int64, onCompletion: (Result<StoredOrderSettings.Setting, Error>) -> Void)

    /// Add or Update orders settings
    ///
    case upsertOrdersSettings(siteID: Int64,
                              orderStatusesFilter: [OrderStatusEnum]?,
                              dateRangeFilter: OrderDateRangeFilter?,
                              onCompletion: (Error?) -> Void)

    /// Clears all the orders settings
    ///
    case resetOrdersSettings

    // MARK: - Products Settings

    /// Loads the products settings
    ///
    case loadProductsSettings(siteID: Int64, onCompletion: (Result<StoredProductSettings.Setting, Error>) -> Void)

    /// Add or Update products settings
    ///
    case upsertProductsSettings(siteID: Int64,
                                sort: String? = nil,
                                stockStatusFilter: ProductStockStatus? = nil,
                                productStatusFilter: ProductStatus? = nil,
                                productTypeFilter: ProductType? = nil,
                                productCategoryFilter: ProductCategory? = nil,
                                onCompletion: (Error?) -> Void)

    /// Clears all the products settings
    ///
    case resetProductsSettings

    // MARK: - General App Settings

    /// Saves the `date` as the last known date that the app was installed. This does not do
    /// anything if there is a persisted installation date already and it is older than the
    /// given `date`.
    ///
    /// - Parameter onCompletion: The `Result`'s success value will be `true` if the installation
    ///                           date was changed and `false` if not.
    ///
    case setInstallationDateIfNecessary(date: Date, onCompletion: ((Result<Bool, Error>) -> Void))

    /// Updates or stores a feedback setting with the provided `type` and `status`.
    ///
    case updateFeedbackStatus(type: FeedbackType, status: FeedbackSettings.Status, onCompletion: ((Result<Void, Error>) -> Void))

    /// Returns whether a specific feedback request should be shown to the user.
    ///
    case loadFeedbackVisibility(type: FeedbackType, onCompletion: (Result<Bool, Error>) -> Void)

    /// Sets the state for the Order Add-ons beta feature switch.
    ///
    case setOrderAddOnsFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void)

    /// Loads the most recent state for the Order Add-ons beta feature switch
    ///
    case loadOrderAddOnsSwitchState(onCompletion: (Result<Bool, Error>) -> Void)

    /// Loads the most recent state for the Order Creation beta feature switch
    ///
    case loadOrderCreationSwitchState(onCompletion: (Result<Bool, Error>) -> Void)

    /// Sets the state for the Order Creation beta feature switch.
    ///
    case setOrderCreationFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void)

    /// Loads the most recent state for the WooCommerce Stripe Payment Gateway extension In-Person Payments beta feature switch
    ///
    case loadStripeInPersonPaymentsSwitchState(onCompletion: (Result<Bool, Error>) -> Void)

    /// Sets the state for the WooCommerce Stripe Payment Gateway extension In-Person Payments beta feature switch
    ///
    case setStripeInPersonPaymentsSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void)

    /// Loads a boolean flag indicating whether the Stripe extension is selected for a given store.
    ///
    case loadStripeExtensionAvailability(siteID: Int64, onCompletion: (Result<Bool, Error>) -> Void)

    /// Sets a boolean flag indicating whether the Stripe extension is selected for a given store.
    ///
    case setStripeExtensionAvailability(siteID: Int64, isAvailable: Bool, onCompletion: (Result<Void, Error>) -> Void)

    /// Sets the state for the Product SKU Input Scanner beta feature switch.
    ///
    case setProductSKUInputScannerFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void)

    /// Loads the most recent state for the Product SKU Input Scanner beta feature switch
    ///
    case loadProductSKUInputScannerFeatureSwitchState(onCompletion: (Result<Bool, Error>) -> Void)

    /// Remember the given card reader (to support automatic reconnection)
    /// where `cardReaderID` is a String e.g. "CHB204909005931"
    ///
    case rememberCardReader(cardReaderID: String, onCompletion: (Result<Void, Error>) -> Void)

    /// Forget any remembered card reader (i.e. automatic reconnection is no longer desired)
    ///
    case forgetCardReader(onCompletion: (Result<Void, Error>) -> Void)

    /// Loads the most recently membered reader, if any (i.e. a reader that should be reconnected to automatically)
    /// E.g.  "CHB204909005931"
    ///
    case loadCardReader(onCompletion: (Result<String?, Error>) -> Void)

    /// Loads the persisted eligibility error information.
    ///
    case loadEligibilityErrorInfo(onCompletion: (Result<EligibilityErrorInfo, Error>) -> Void)

    /// Saves an `EligibilityErrorInfo` locally.
    /// There can only be one persisted instance. Subsequent calls will overwrite the existing data.
    ///
    case setEligibilityErrorInfo(errorInfo: EligibilityErrorInfo, onCompletion: (Result<Void, Error>) -> Void)

    /// Clears the persisted eligibility error information.
    ///
    case resetEligibilityErrorInfo

    /// Sets the last time when Jetpack benefits banner is dismissed in the Dashboard.
    ///
    case setJetpackBenefitsBannerLastDismissedTime(time: Date)

    /// Loads the visibility of Jetpack benefits banner in the Dashboard based on the last dismissal time.
    /// The banner is not shown for five days after the last time it is dismissed.
    /// There are other conditions for showing the Jetpack banner, like when the site is Jetpack CP connected.
    ///
    case loadJetpackBenefitsBannerVisibility(currentTime: Date, calendar: Calendar, onCompletion: (Bool) -> Void)

    // MARK: - General Store Settings

    /// Sets telemetry availability status information.
    ///
    case setTelemetryAvailability(siteID: Int64, isAvailable: Bool)

    /// Sets telemetry last reported time information.
    ///
    case setTelemetryLastReportedTime(siteID: Int64, time: Date)

    /// Loads telemetry information - availability status and last reported time.
    ///
    case getTelemetryInfo(siteID: Int64, onCompletion: (Bool, Date?) -> Void)

    /// Sets the last state of the simple payments taxes toggle for a provided store.
    ///
    case setSimplePaymentsTaxesToggleState(siteID: Int64, isOn: Bool, onCompletion: (Result<Void, Error>) -> Void)

    /// Get the last state of the simple payments taxes toggle for a provided store.
    ///
    case getSimplePaymentsTaxesToggleState(siteID: Int64, onCompletion: (Result<Bool, Error>) -> Void)

    /// Clears all the products settings
    ///
    case resetGeneralStoreSettings
}
