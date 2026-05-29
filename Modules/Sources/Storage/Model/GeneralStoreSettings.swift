import Foundation
import Codegen

/// Models a wrapper of a dictionary from site ID to store settings.
/// These entities will be serialised to a plist file
///
public struct GeneralStoreSettingsBySite: Codable, Equatable {
    public let storeSettingsBySite: [Int64: GeneralStoreSettings]

    public init(storeSettingsBySite: [Int64: GeneralStoreSettings]) {
        self.storeSettingsBySite = storeSettingsBySite
    }
}

/// An encodable/decodable data structure that can be used to save files. This contains
/// miscellaneous store settings (unique for each store).
///
public struct GeneralStoreSettings: Codable, Equatable, GeneratedCopiable {

    /// The store unique identifier.
    ///
    public let storeID: String?

    /// The state(`true` or `false`) for the view add-on beta feature switch.
    ///
    public let isTelemetryAvailable: Bool

    /// Last time when telemetry was successfully sent.
    ///
    public let telemetryLastReportedTime: Date?

    /// Stores the last simple payments toggle state.
    ///
    public let areSimplePaymentTaxesEnabled: Bool

    /// Stores the preferred payment gateway for In-Person Payments
    ///
    public let preferredInPersonPaymentGateway: String?

    /// Stores whether the Enable Cash on Delivery In-Person Payments Onboarding step has been skipped for this store
    ///
    public let skippedCashOnDeliveryOnboardingStep: Bool

    /// The raw value string of `StatsTimeRangeV4` that indicates the last selected time range tab in store stats.
    public var lastSelectedStatsTimeRange: String

    /// The raw value string of `StatsTimeRangeV4` that indicates the custom time range tab in store stats.
    public var customStatsTimeRange: String

    /// We keep the dates of the first In Person Payments transactions using this phone/store/reader combination for
    public let firstInPersonPaymentsTransactionsByReaderType: [CardReaderType: Date]

    /// The selected tax rate to apply to the orders
    public let selectedTaxRateID: Int64?

    /// The set of cards for the Analytics Hub, with their enabled status and sort order.
    public let analyticsHubCards: [AnalyticsCard]?

    /// The set of cards for the Dashboard screen, with their enabled status and sort order.
    public let dashboardCards: [DashboardCard]?

    /// The raw value string of `StatsTimeRangeV4` that indicates the last selected time range tab in Performance dashboard card.
    public var lastSelectedPerformanceTimeRange: String

    /// The raw value of `DashboardRevenueStatsType` indicating the last selected revenue metric on the Performance card.
    /// Empty string means "use the default" (Total).
    public var lastSelectedDashboardRevenueStatsType: String

    /// The raw value string of `StatsTimeRangeV4` that indicates the last selected time range tab in Top Performers dashboard card.
    public var lastSelectedTopPerformersTimeRange: String

    /// The raw value string of `MostActiveCouponsTimeRange` that indicates the last selected time range tab in Most active coupons card.
    public var lastSelectedMostActiveCouponsTimeRange: String

    /// The raw value of stock type indicating the last selected type in the Stock dashboard card.
    public var lastSelectedStockType: String?

    /// The raw value of order status indicating the last selected order status in the Most recent orders dashboard card.
    public var lastSelectedOrderStatus: String?

    /// Products marked as favorite by users.
    ///
    public var favoriteProductIDs: [Int64]

    /// Search terms history for different item types in the Point of Sale.
    ///
    public var searchTermsByKey: [String: [String]]

    /// Whether the POS tab is visible for this store.
    ///
    public var isPOSTabVisible: Bool?

    /// The last time POS was opened for this store.
    ///
    public var lastPOSOpenedDate: Date?

    /// The date of the first POS catalog sync for this store.
    ///
    public var firstPOSCatalogSyncDate: Date?

    /// Whether we should sync catalog data over cellular connections for this store
    ///
    public var syncPOSCatalogOverCellular: Bool

    /// The last time the sunset warning banner was dismissed for this store.
    /// Used to throttle the banner to once every 14 days.
    ///
    public var lastSunsetWarningDismissedDate: Date?

    /// Whether this site is eligible for In-Person Payments countries gated by remote flags.
    /// `nil` until the eligibility refresher has run for the first time. Cached based on
    /// the relevant remote feature flag for the site's country, with US/PR/CA/GB
    /// short-circuited to `true`. Australia uses its own WooPayments-only flag.
    public var isCardPresentPaymentsCountryExpansionEligible: Bool?

    public init(storeID: String? = nil,
                isTelemetryAvailable: Bool = false,
                telemetryLastReportedTime: Date? = nil,
                areSimplePaymentTaxesEnabled: Bool = false,
                preferredInPersonPaymentGateway: String? = nil,
                skippedCashOnDeliveryOnboardingStep: Bool = false,
                lastSelectedStatsTimeRange: String = "",
                customStatsTimeRange: String = "",
                firstInPersonPaymentsTransactionsByReaderType: [CardReaderType: Date] = [:],
                selectedTaxRateID: Int64? = nil,
                analyticsHubCards: [AnalyticsCard]? = nil,
                dashboardCards: [DashboardCard]? = nil,
                lastSelectedPerformanceTimeRange: String = "",
                lastSelectedDashboardRevenueStatsType: String = "",
                lastSelectedTopPerformersTimeRange: String = "",
                lastSelectedMostActiveCouponsTimeRange: String = "",
                lastSelectedStockType: String? = nil,
                lastSelectedOrderStatus: String? = nil,
                favoriteProductIDs: [Int64] = [],
                searchTermsByKey: [String: [String]] = [:],
                isPOSTabVisible: Bool? = nil,
                lastPOSOpenedDate: Date? = nil,
                firstPOSCatalogSyncDate: Date? = nil,
                syncPOSCatalogOverCellular: Bool = true,
                lastSunsetWarningDismissedDate: Date? = nil,
                isCardPresentPaymentsCountryExpansionEligible: Bool? = nil) {
        self.storeID = storeID
        self.isTelemetryAvailable = isTelemetryAvailable
        self.telemetryLastReportedTime = telemetryLastReportedTime
        self.areSimplePaymentTaxesEnabled = areSimplePaymentTaxesEnabled
        self.preferredInPersonPaymentGateway = preferredInPersonPaymentGateway
        self.skippedCashOnDeliveryOnboardingStep = skippedCashOnDeliveryOnboardingStep
        self.lastSelectedStatsTimeRange = lastSelectedStatsTimeRange
        self.customStatsTimeRange = customStatsTimeRange
        self.firstInPersonPaymentsTransactionsByReaderType = firstInPersonPaymentsTransactionsByReaderType
        self.selectedTaxRateID = selectedTaxRateID
        self.analyticsHubCards = analyticsHubCards
        self.dashboardCards = dashboardCards
        self.lastSelectedPerformanceTimeRange = lastSelectedPerformanceTimeRange
        self.lastSelectedDashboardRevenueStatsType = lastSelectedDashboardRevenueStatsType
        self.lastSelectedTopPerformersTimeRange = lastSelectedTopPerformersTimeRange
        self.lastSelectedMostActiveCouponsTimeRange = lastSelectedMostActiveCouponsTimeRange
        self.lastSelectedStockType = lastSelectedStockType
        self.lastSelectedOrderStatus = lastSelectedOrderStatus
        self.favoriteProductIDs = favoriteProductIDs
        self.searchTermsByKey = searchTermsByKey
        self.isPOSTabVisible = isPOSTabVisible
        self.lastPOSOpenedDate = lastPOSOpenedDate
        self.firstPOSCatalogSyncDate = firstPOSCatalogSyncDate
        self.syncPOSCatalogOverCellular = syncPOSCatalogOverCellular
        self.lastSunsetWarningDismissedDate = lastSunsetWarningDismissedDate
        self.isCardPresentPaymentsCountryExpansionEligible = isCardPresentPaymentsCountryExpansionEligible
    }

    public func erasingSelectedTaxRateID() -> GeneralStoreSettings {
        GeneralStoreSettings(storeID: storeID,
                             isTelemetryAvailable: isTelemetryAvailable,
                             telemetryLastReportedTime: telemetryLastReportedTime,
                             areSimplePaymentTaxesEnabled: areSimplePaymentTaxesEnabled,
                             preferredInPersonPaymentGateway: preferredInPersonPaymentGateway,
                             skippedCashOnDeliveryOnboardingStep: skippedCashOnDeliveryOnboardingStep,
                             lastSelectedStatsTimeRange: lastSelectedStatsTimeRange,
                             customStatsTimeRange: customStatsTimeRange,
                             firstInPersonPaymentsTransactionsByReaderType: firstInPersonPaymentsTransactionsByReaderType,
                             selectedTaxRateID: nil,
                             analyticsHubCards: analyticsHubCards,
                             dashboardCards: dashboardCards,
                             lastSelectedPerformanceTimeRange: lastSelectedPerformanceTimeRange,
                             lastSelectedDashboardRevenueStatsType: lastSelectedDashboardRevenueStatsType,
                             lastSelectedTopPerformersTimeRange: lastSelectedTopPerformersTimeRange,
                             lastSelectedStockType: lastSelectedStockType,
                             lastSelectedOrderStatus: lastSelectedOrderStatus,
                             favoriteProductIDs: favoriteProductIDs,
                             searchTermsByKey: searchTermsByKey,
                             isPOSTabVisible: isPOSTabVisible,
                             lastPOSOpenedDate: lastPOSOpenedDate,
                             firstPOSCatalogSyncDate: firstPOSCatalogSyncDate,
                             lastSunsetWarningDismissedDate: lastSunsetWarningDismissedDate,
                             isCardPresentPaymentsCountryExpansionEligible: isCardPresentPaymentsCountryExpansionEligible)
    }
}

// MARK: Custom Decoding
extension GeneralStoreSettings {
    /// We need a custom decoding to make sure it doesn't fails when this type is updated (eg: when adding/removing new properties)
    /// Otherwise we will lose previously stored information.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.storeID = try container.decodeIfPresent(String.self, forKey: .storeID)
        self.isTelemetryAvailable = try container.decodeIfPresent(Bool.self, forKey: .isTelemetryAvailable) ?? false
        self.telemetryLastReportedTime = try container.decodeIfPresent(Date.self, forKey: .telemetryLastReportedTime)
        self.areSimplePaymentTaxesEnabled = try container.decodeIfPresent(Bool.self, forKey: .areSimplePaymentTaxesEnabled) ?? false
        self.preferredInPersonPaymentGateway = try container.decodeIfPresent(String.self, forKey: .preferredInPersonPaymentGateway)
        self.skippedCashOnDeliveryOnboardingStep = try container.decodeIfPresent(Bool.self, forKey: .skippedCashOnDeliveryOnboardingStep) ?? false
        self.lastSelectedStatsTimeRange = try container.decodeIfPresent(String.self, forKey: .lastSelectedStatsTimeRange) ?? ""
        self.customStatsTimeRange = try container.decodeIfPresent(String.self, forKey: .customStatsTimeRange) ?? ""
        self.firstInPersonPaymentsTransactionsByReaderType = try container.decodeIfPresent([CardReaderType: Date].self,
                                                                                           forKey: .firstInPersonPaymentsTransactionsByReaderType) ?? [:]
        self.selectedTaxRateID = try container.decodeIfPresent(Int64.self, forKey: .selectedTaxRateID)
        self.analyticsHubCards = try container.decodeIfPresent([AnalyticsCard].self, forKey: .analyticsHubCards)
        self.dashboardCards = try container.decodeIfPresent([DashboardCard].self, forKey: .dashboardCards)

        self.lastSelectedPerformanceTimeRange = try container.decodeIfPresent(String.self, forKey: .lastSelectedPerformanceTimeRange) ?? ""
        self.lastSelectedDashboardRevenueStatsType = try container.decodeIfPresent(String.self, forKey: .lastSelectedDashboardRevenueStatsType) ?? ""
        self.lastSelectedTopPerformersTimeRange = try container.decodeIfPresent(String.self, forKey: .lastSelectedTopPerformersTimeRange) ?? ""
        self.lastSelectedMostActiveCouponsTimeRange = try container.decodeIfPresent(String.self, forKey: .lastSelectedMostActiveCouponsTimeRange) ?? ""
        self.lastSelectedStockType = try container.decodeIfPresent(String.self, forKey: .lastSelectedStockType)
        self.lastSelectedOrderStatus = try container.decodeIfPresent(String.self, forKey: .lastSelectedOrderStatus)
        self.favoriteProductIDs = try container.decodeIfPresent([Int64].self,
                                                                forKey: .favoriteProductIDs) ?? []
        self.searchTermsByKey = try container.decodeIfPresent([String: [String]].self, forKey: .searchTermsByKey) ?? [:]

        self.isPOSTabVisible = try container.decodeIfPresent(Bool.self, forKey: .isPOSTabVisible)
        self.lastPOSOpenedDate = try container.decodeIfPresent(Date.self, forKey: .lastPOSOpenedDate)
        self.firstPOSCatalogSyncDate = try container.decodeIfPresent(Date.self, forKey: .firstPOSCatalogSyncDate)
        self.syncPOSCatalogOverCellular = try container.decodeIfPresent(Bool.self, forKey: .syncPOSCatalogOverCellular) ?? true
        self.lastSunsetWarningDismissedDate = try container.decodeIfPresent(Date.self, forKey: .lastSunsetWarningDismissedDate)
        self.isCardPresentPaymentsCountryExpansionEligible = try container.decodeIfPresent(
            Bool.self,
            forKey: .isCardPresentPaymentsCountryExpansionEligible
        )

        // Decode new properties with `decodeIfPresent` and provide a default value if necessary.
    }
}
