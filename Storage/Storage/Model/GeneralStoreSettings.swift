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

    /// We keep the dates of the first In Person Payments transactions using this phone/store/reader combination for
    public let firstInPersonPaymentsTransactionsByReaderType: [CardReaderType: Date]

    /// The selected tax rate to apply to the orders
    public let selectedTaxRateID: Int64?

    /// The set of cards for the Analytics Hub, with their enabled status and sort order.
    public let analyticsHubCards: Set<AnalyticsCard>?

    public init(storeID: String? = nil,
                isTelemetryAvailable: Bool = false,
                telemetryLastReportedTime: Date? = nil,
                areSimplePaymentTaxesEnabled: Bool = false,
                preferredInPersonPaymentGateway: String? = nil,
                skippedCashOnDeliveryOnboardingStep: Bool = false,
                lastSelectedStatsTimeRange: String = "",
                firstInPersonPaymentsTransactionsByReaderType: [CardReaderType: Date] = [:],
                selectedTaxRateID: Int64? = nil,
                analyticsHubCards: Set<AnalyticsCard>? = nil) {
        self.storeID = storeID
        self.isTelemetryAvailable = isTelemetryAvailable
        self.telemetryLastReportedTime = telemetryLastReportedTime
        self.areSimplePaymentTaxesEnabled = areSimplePaymentTaxesEnabled
        self.preferredInPersonPaymentGateway = preferredInPersonPaymentGateway
        self.skippedCashOnDeliveryOnboardingStep = skippedCashOnDeliveryOnboardingStep
        self.lastSelectedStatsTimeRange = lastSelectedStatsTimeRange
        self.firstInPersonPaymentsTransactionsByReaderType = firstInPersonPaymentsTransactionsByReaderType
        self.selectedTaxRateID = selectedTaxRateID
        self.analyticsHubCards = analyticsHubCards
    }

    public func erasingSelectedTaxRateID() -> GeneralStoreSettings {
        GeneralStoreSettings(storeID: storeID,
                             isTelemetryAvailable: isTelemetryAvailable,
                             telemetryLastReportedTime: telemetryLastReportedTime,
                             areSimplePaymentTaxesEnabled: areSimplePaymentTaxesEnabled,
                             preferredInPersonPaymentGateway: preferredInPersonPaymentGateway,
                             skippedCashOnDeliveryOnboardingStep: skippedCashOnDeliveryOnboardingStep,
                             lastSelectedStatsTimeRange: lastSelectedStatsTimeRange,
                             firstInPersonPaymentsTransactionsByReaderType: firstInPersonPaymentsTransactionsByReaderType,
                             selectedTaxRateID: nil,
                             analyticsHubCards: analyticsHubCards)
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
        self.firstInPersonPaymentsTransactionsByReaderType = try container.decodeIfPresent([CardReaderType: Date].self,
                                                                                           forKey: .firstInPersonPaymentsTransactionsByReaderType) ?? [:]
        self.selectedTaxRateID = try container.decodeIfPresent(Int64.self, forKey: .selectedTaxRateID)
        self.analyticsHubCards = try container.decodeIfPresent(Set<AnalyticsCard>.self, forKey: .analyticsHubCards)

        // Decode new properties with `decodeIfPresent` and provide a default value if necessary.
    }
}
