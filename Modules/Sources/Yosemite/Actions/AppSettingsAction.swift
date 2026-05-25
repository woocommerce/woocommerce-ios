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
                              productFilter: FilterOrdersByProduct?,
                              customerFilter: CustomerFilter?,
                              salesChannelFilter: SalesChannelFilter?,
                              onCompletion: (Error?) -> Void)

    /// Clears all the orders settings
    ///
    case resetOrdersSettings

    // MARK: - Order filter history

    /// Inserts or updates the order filter history
    case upsertOrderFilterHistory(filter: StoredOrderSettings.Setting,
                                  onCompletion: (Error?) -> Void)

    /// Retrieves all persisted order filters for a given site
    case loadOrderFilterHistory(siteID: Int64, onCompletion: (Result<[StoredOrderSettings.Setting], Error>) -> Void)

    /// Removes a filter from the persisted history
    case removeFromOrderFilterHistory(filter: StoredOrderSettings.Setting,
                                      onCompletion: (Error?) -> Void)

    /// Clears all the order filter history for a given site
    case resetOrderFilterHistory(siteID: Int64, onCompletion: (Error?) -> Void)

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
                                favoriteProduct: Bool = false,
                                onCompletion: (Error?) -> Void)

    /// Clears all the products settings
    ///
    case resetProductsSettings

    // MARK: - Product filter history

    /// Inserts or updates the product filter history
    case upsertProductFilterHistory(filter: StoredProductSettings.Setting,
                                    onCompletion: (Error?) -> Void)

    /// Retrieves all persisted product filters for a given site
    case loadProductFilterHistory(siteID: Int64, onCompletion: (Result<[StoredProductSettings.Setting], Error>) -> Void)

    /// Removes a product filter from the persisted history
    case removeFromProductFilterHistory(filter: StoredProductSettings.Setting,
                                        onCompletion: (Error?) -> Void)

    /// Clears all the product filter history for a given site
    case resetProductFilterHistory(siteID: Int64, onCompletion: (Error?) -> Void)

    // MARK: - Bookings Filters

    /// Loads the booking filters
    ///
    case loadBookingFilters(siteID: Int64, onCompletion: (Result<StoredBookingFilters.Filters, Error>) -> Void)

    /// Add or Update booking filters
    ///
    case upsertBookingFilters(siteID: Int64,
                              filters: StoredBookingFilters.Filters,
                              onCompletion: (Error?) -> Void)

    /// Clears all the booking filters
    ///
    case resetBookingFilters

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

    /// Sets the dismiss state for the Custom Fields top banner
    ///
    case dismissCustomFieldsTopBanner(onCompletion: (Result<Void, Error>) -> Void)

    /// Loads the dismiss state of the Custom Fields top banner
    ///
    case loadCustomFieldsTopBannerDismissState(onCompletion: (Bool) -> Void)

    // MARK: - General Store Settings

    /// Sets the store uuid.
    ///
    case setStoreID(siteID: Int64, id: String?)

    /// Gets the store uuid.
    ///
    case getStoreID(siteID: Int64, onCompletion: (String?) -> Void)

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

    // MARK: - Stats custom time range tab

    case setCustomStatsTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4)

    case loadCustomStatsTimeRange(siteID: Int64, onCompletion: (StatsTimeRangeV4?) -> Void)

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

    // MARK: - Tax Rates

    /// Stores the selected tax rate to be applied to orders. Passing a nil value erases it. This is site-specific.
    case setSelectedTaxRateID(id: Int64?, siteID: Int64)

    /// Loads the selected tax rate to be applied to orders. This is site-specific.
    case loadSelectedTaxRateID(siteID: Int64, onCompletion: (Int64?) -> Void)

    // MARK: - Analytics Hub Cards

    /// Stores an ordered array of cards for the Analytics Hub.
    ///
    case setAnalyticsHubCards(siteID: Int64, cards: [AnalyticsCard])

    /// Loads the stored, ordered array of cards for the Analytics Hub.
    ///
    case loadAnalyticsHubCards(siteID: Int64, onCompletion: ([AnalyticsCard]?) -> Void)

    // MARK: - Dashboard Cards

    /// Stores an ordered array of cards for the Dashboard screen.
    ///
    case setDashboardCards(siteID: Int64, cards: [DashboardCard])

    /// Loads the stored, ordered array of cards for the Dashboard screen.
    ///
    case loadDashboardCards(siteID: Int64, onCompletion: ([DashboardCard]?) -> Void)

    /// Stores the last selected time range for the Performance dashboard card.
    ///
    case setLastSelectedPerformanceTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4)

    /// Loads the last selected time range for the Performance dashboard card.
    ///
    case loadLastSelectedPerformanceTimeRange(siteID: Int64, onCompletion: (StatsTimeRangeV4?) -> Void)

    /// Stores the last selected revenue metric (Gross / Net / Total) for the Performance dashboard card.
    ///
    case setLastSelectedDashboardRevenueStatsType(siteID: Int64, revenueType: DashboardRevenueStatsType)

    /// Loads the last selected revenue metric for the Performance dashboard card. `nil` if the merchant
    /// has not yet picked one (the UI should fall back to the default `.total`).
    ///
    case loadLastSelectedDashboardRevenueStatsType(siteID: Int64, onCompletion: (DashboardRevenueStatsType?) -> Void)

    /// Stores the last selected time range for the Top Performers dashboard card.
    ///
    case setLastSelectedTopPerformersTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4)

    /// Loads the last selected time range for the Top Performers dashboard card.
    ///
    case loadLastSelectedTopPerformersTimeRange(siteID: Int64, onCompletion: (StatsTimeRangeV4?) -> Void)

    /// Stores the last selected time range for the Most Active coupons dashboard card.
    ///
    case setLastSelectedMostActiveCouponsTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4)

    /// Loads the last selected time range for the Most Active coupons dashboard card.
    ///
    case loadLastSelectedMostActiveCouponsTimeRange(siteID: Int64, onCompletion: (StatsTimeRangeV4?) -> Void)

    /// Stores the last selected stock type for the Stock dashboard card.
    ///
    case setLastSelectedStockType(siteID: Int64, type: String)

    /// Loads the last selected stock type for the Stock dashboard card.
    ///
    case loadLastSelectedStockType(siteID: Int64, onCompletion: (String?) -> Void)

    /// Stores the last selected order status for the Most recent orders dashboard card.
    ///
    case setLastSelectedOrderStatus(siteID: Int64, status: String?)

    /// Loads the last selected order status for the Most recent orders dashboard card.
    ///
    case loadLastSelectedOrderStatus(siteID: Int64, onCompletion: (String?) -> Void)

    /// Stores the product ID as favorite.
    ///
    case setProductIDAsFavorite(productID: Int64, siteID: Int64)

    /// Removes the product ID from favorite list.
    ///
    case removeProductIDAsFavorite(productID: Int64, siteID: Int64)

    /// Loads the favorite products.
    ///
    case loadFavoriteProductIDs(siteID: Int64, onCompletion: ([Int64]) -> Void)

    // MARK: - Application passwords Experiment feature

    /// Sets the state of the App Passwords Experiment feature
    ///
    case setAppPasswordsExperimentSettingState(isOn: Bool, onCompletion: (Result<Void, Error>) -> Void)

    /// Loads Loads the state of the App Passwords Experiment feature
    ///
    case getAppPasswordsExperimentSettingState(onCompletion: (Bool) -> Void)

    // MARK: - Point of Sale Surveys

    /// Sets the POS survey notification as scheduled for potential merchants
    ///
    case setPOSSurveyPotentialMerchantNotificationScheduled(onCompletion: (Result<Void, Error>) -> Void)

    /// Gets whether the POS survey notification has been scheduled for potential merchants
    ///
    case getPOSSurveyPotentialMerchantNotificationScheduled(onCompletion: (Bool) -> Void)

    /// Sets the POS survey notification as scheduled for current merchants
    ///
    case setPOSSurveyCurrentMerchantNotificationScheduled(onCompletion: (Result<Void, Error>) -> Void)

    /// Gets whether the POS survey notification has been scheduled for current merchants
    ///
    case getPOSSurveyCurrentMerchantNotificationScheduled(onCompletion: (Bool) -> Void)

    /// Sets that POS mode has been opened at least once
    ///
    case setHasPOSBeenOpenedAtLeastOnce(onCompletion: (Result<Void, Error>) -> Void)

    /// Gets whether POS mode has been opened at least once
    ///
    case getHasPOSBeenOpenedAtLeastOnce(onCompletion: (Bool) -> Void)

    /// Resets all POS survey notification scheduled states
    /// At the moment this one is used for testing only. To remove in WOOMOB-1480
    case resetPOSSurveyNotificationScheduled(onCompletion: (Result<Void, Error>) -> Void)

    // MARK: - POS Sync Eligibility Tracking

    /// Sets the last time POS was opened for a specific site
    ///
    case setPOSLastOpenedDate(siteID: Int64, date: Date, onCompletion: () -> Void)

    /// Gets the last time POS was opened for a specific site
    ///
    case getPOSLastOpenedDate(siteID: Int64, onCompletion: (Date?) -> Void)

    /// Sets the date of the first POS catalog sync for a specific site
    ///
    case setFirstPOSCatalogSyncDate(siteID: Int64, date: Date, onCompletion: () -> Void)

    /// Gets the date of the first POS catalog sync for a specific site
    ///
    case getFirstPOSCatalogSyncDate(siteID: Int64, onCompletion: (Date?) -> Void)

    /// Sets whether we should allow cellular data use downloading POS catalogs for a specific site
    ///
    case setPOSLocalCatalogCellularDataAllowed(siteID: Int64, allowed: Bool, onCompletion: () -> Void)

    /// Gets whether we should allow cellular data use downloading POS catalogs for a specific site
    case getPOSLocalCatalogCellularDataAllowed(siteID: Int64, onCompletion: (Bool) -> Void)
}
