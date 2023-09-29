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

    /// Sets the dismiss state for the EU Shipping Notice.
    ///
    case dismissEUShippingNotice(onCompletion: (Result<Void, Error>) -> Void)

    /// Loads the most recent dismiss state for the EU Shipping Notice.
    ///
    case loadEUShippingNoticeDismissState(onCompletion: (Result<Bool, Error>) -> Void)

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

    /// Clears all the products settings
    ///
    case resetGeneralStoreSettings

    // MARK: - Feature Announcement Card Visibility

    case setFeatureAnnouncementDismissed(
        campaign: FeatureAnnouncementCampaign,
        remindAfterDays: Int?,
        onCompletion: ((Result<Bool, Error>) -> ())?
    )

    case getFeatureAnnouncementVisibility(campaign: FeatureAnnouncementCampaign, onCompletion: (Result<Bool, Error>) -> ())

    // MARK: - Stats Time Range Tab

    case setLastSelectedStatsTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4)

    case loadLastSelectedStatsTimeRange(siteID: Int64, onCompletion: (StatsTimeRangeV4?) -> Void)

    /// Loads whether the user finished an IPP transaction for the given siteID
    ///
    case loadSiteHasAtLeastOneIPPTransactionFinished(siteID: Int64, onCompletion: (Bool) -> Void)

    // MARK: - In Person Payments

    /// Sets the last state of the simple payments taxes toggle for a provided store.
    ///
    case setSimplePaymentsTaxesToggleState(siteID: Int64, isOn: Bool, onCompletion: (Result<Void, Error>) -> Void)

    /// Get the last state of the simple payments taxes toggle for a provided store.
    ///
    case getSimplePaymentsTaxesToggleState(siteID: Int64, onCompletion: (Result<Bool, Error>) -> Void)

    /// Sets the preferred payment gateway for In-Person Payments
    ///
    case setPreferredInPersonPaymentGateway(siteID: Int64, gateway: String)

    /// Gets the preferred payment gateway for In-Person Payments
    ///
    case getPreferredInPersonPaymentGateway(siteID: Int64, onCompletion: (String?) -> Void)

    /// Forgets the preferred payment gateway for In-Person Payments
    ///
    case forgetPreferredInPersonPaymentGateway(siteID: Int64)

    /// Marks the Enable Cash on Delivery In-Person Payments Onboarding step as skipped
    ///
    case setSkippedCashOnDeliveryOnboardingStep(siteID: Int64)

    /// Gets whether the Enable Cash on Delivery In-Person Payments Onboarding step has been skipped
    ///
    case getSkippedCashOnDeliveryOnboardingStep(siteID: Int64, onCompletion: (Bool) -> Void)

    /// Loads the date of the first In Person Payments transaction made on this device using a particular card reader type. This is site-specific.
    /// N.B. this was added in 2023-04, so the date will not be the "first" for any stores using In Person Payments prior to that date.
    ///
    case loadFirstInPersonPaymentsTransactionDate(siteID: Int64, cardReaderType: CardReaderType, onCompletion: (Date?) -> Void)

    /// Stores the current date as the first In Person Payments transaction made on this device using a particular card reader type. This is site-specific.
    /// Existing values are preserved, this will not overwrite previously stored dates.
    ///
    case storeInPersonPaymentsTransactionIfFirst(siteID: Int64, cardReaderType: CardReaderType)

    // MARK: - Local Announcement Visibility

    case getLocalAnnouncementVisibility(announcement: LocalAnnouncement, onCompletion: (Bool) -> ())

    case setLocalAnnouncementDismissed(announcement: LocalAnnouncement, onCompletion: (Result<Void, Error>) -> Void)

    // MARK: - Tax Rates

    /// Stores the selected tax rate to be applied to orders. Passing a nil value erases it. This is site-specific.
    case setSelectedTaxRateID(id: Int64?, siteID: Int64)

    /// Loads the selected tax rate to be applied to orders. This is site-specific.
    case loadSelectedTaxRateID(siteID: Int64, onCompletion: (Int64?) -> Void)
}
