import Foundation

/// Whether the device + site can use Apple's Tap to Pay reader for POS payments.
///
/// `unknown` while the check is in flight, then resolves to `available` or
/// `unavailable(reason:)`. The reason is plumbed up to analytics so we can spot
/// merchants who can't access TTP from their device or site.
public enum POSTapToPayAvailabilityState: Equatable {
    case unknown
    case available
    case unavailable(reason: POSTapToPayUnavailableReason)
}

public enum POSTapToPayUnavailableReason: String, Equatable {
    /// The build is not enabling the POS phone TTP feature flag.
    case featureFlagDisabled
    /// The device hardware doesn't support TTP (e.g. older iPhone, iPad).
    case deviceNotSupported
    /// The store's country / payment plugin doesn't support TTP yet.
    case siteNotEligible
}

/// Checks whether the device + site can use Apple Tap to Pay for POS payments.
public protocol POSTapToPayAvailabilityChecking {
    /// Resolves to `.available` only when the feature flag is on, the device
    /// supports the built-in reader, and the site's country + plugin status
    /// allow it. Otherwise resolves to `.unavailable(reason:)`.
    func checkAvailability() async -> POSTapToPayAvailabilityState
}
