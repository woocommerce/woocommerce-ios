import Foundation

/// Represents the reasons why a site may be ineligible for POS.
public enum POSIneligibleReason: Equatable {
    case unsupportedWooCommerceVersion(minimumVersion: String)
    case siteSettingsNotAvailable
    case wooCommercePluginNotFound
    case selfDeallocated
}

/// Represents the eligibility state for POS.
public enum POSEligibilityState: Equatable {
    case eligible
    case ineligible(reason: POSIneligibleReason)
}
