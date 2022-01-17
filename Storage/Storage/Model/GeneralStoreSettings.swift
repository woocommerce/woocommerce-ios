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

    /// The state(`true` or `false`) for the view add-on beta feature switch.
    ///
    public let isTelemetryAvailable: Bool

    /// Last time when telemetry was successfully sent.
    ///
    public let telemetryLastReportedTime: Date?

    /// Stores the last simple payments toggle state.
    ///
    public let areSimplePaymentTaxesEnabled: Bool

    /// Indicates whether the merchant wants to use the Stripe Extension to process payments
    ///
    public let isStripeExtensionSelected: Bool


    public init(isTelemetryAvailable: Bool = false,
                telemetryLastReportedTime: Date? = nil,
                isStripeExtensionSelected: Bool = false,
                areSimplePaymentTaxesEnabled: Bool = false) {
        self.isTelemetryAvailable = isTelemetryAvailable
        self.telemetryLastReportedTime = telemetryLastReportedTime
        self.isStripeExtensionSelected = isStripeExtensionSelected
        self.areSimplePaymentTaxesEnabled = areSimplePaymentTaxesEnabled
    }
}

// MARK: Custom Decoding
extension GeneralStoreSettings {
    /// We need a custom decoding to make sure it doesn't fails when this type is updated (eg: when adding/removing new properties)
    /// Otherwise we will lose previously stored information.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.isTelemetryAvailable = try container.decodeIfPresent(Bool.self, forKey: .isTelemetryAvailable) ?? false
        self.isStripeExtensionSelected = try container.decodeIfPresent(Bool.self, forKey: .isStripeExtensionSelected) ?? false
        self.telemetryLastReportedTime = try container.decodeIfPresent(Date.self, forKey: .telemetryLastReportedTime)
        self.areSimplePaymentTaxesEnabled = try container.decodeIfPresent(Bool.self, forKey: .areSimplePaymentTaxesEnabled) ?? false

        // Decode new properties with `decodeIfPresent` and provide a default value if necessary.
    }
}
