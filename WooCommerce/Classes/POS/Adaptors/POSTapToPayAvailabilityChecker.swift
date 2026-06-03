import Foundation
import PointOfSale
import enum Experiments.FeatureFlag
import protocol Experiments.FeatureFlagService
import enum Yosemite.CardPresentPaymentAction
import enum Yosemite.CardReaderDiscoveryMethod
import enum Hardware.CardReaderType
import struct Yosemite.CardPresentPaymentsConfiguration
import protocol Yosemite.StoresManager
import protocol Yosemite.POSEligibilityServiceProtocol

/// Resolves Tap to Pay availability for the current POS session.
///
/// Four gates, evaluated in order — fail fast on whichever is first to deny:
/// 1. The `pointOfSaleTapToPay` feature flag (cheapest check, shortcuts the rest).
/// 2. Country support — `CardPresentPaymentsConfiguration.supportedReaders` for the
///    store's country must include `.tapToPay`. POS now opens worldwide, but TTP is
///    still tied to the country's IPP capability config (US, GB on iOS today).
/// 3. Device support — Stripe's `Terminal.shared.supportsReaders(of: .appleBuiltIn, ...)`,
///    dispatched via `CardPresentPaymentAction.checkDeviceSupport`.
/// 4. Site eligibility — proxied off cached POS tab visibility (defensive: ensures
///    the site has at least been validated as POS-visible in this session).
///
/// One-shot — `POSTapToPayAvailabilityController` calls `checkAvailability()` once on
/// POS entry and holds the result for the rest of the session.
final class POSTapToPayAvailabilityChecker: POSTapToPayAvailabilityChecking {
    private let siteID: Int64
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let eligibilityService: POSEligibilityServiceProtocol
    /// Returns `nil` when no card-payments configuration has been resolved yet for
    /// the merchant — either an unknown country or an expansion-flag-gated country
    /// (Spain / FR / DE / AU / NZ / SG …) whose remote-feature-flag check hasn't
    /// completed. The TTP availability check fails closed on `nil` so we never
    /// silently render TTP UI for a not-yet-known configuration.
    private let configurationLoader: () -> CardPresentPaymentsConfiguration?

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         eligibilityService: POSEligibilityServiceProtocol,
         configurationLoader: @escaping () -> CardPresentPaymentsConfiguration? = {
             // Treat the loader's `.unknown` fallback as "no configuration loaded"
             // so we fail closed instead of silently returning an empty
             // `supportedReaders` array that would have to be sniffed for-zero by
             // every caller. `.unknown` shows up when SiteAddress hasn't been
             // populated yet (early bootstrap) or when the expansion-flag-gated
             // eligibility cache hasn't been refreshed for the merchant's country.
             let configuration = CardPresentConfigurationLoader().configuration
             return configuration.countryCode == .unknown ? nil : configuration
         }) {
        self.siteID = siteID
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.eligibilityService = eligibilityService
        self.configurationLoader = configurationLoader
    }

    func checkAvailability() async -> POSTapToPayAvailabilityState {
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleTapToPay) else {
            return .unavailable(reason: .featureFlagDisabled)
        }
        guard countrySupportsTapToPay() else {
            // Per the unavailable-reasons enum, country / payment-plugin support falls under
            // `.siteNotEligible`. Same code path the previous IPP-eligibility gate used.
            return .unavailable(reason: .siteNotEligible)
        }
        guard await deviceSupportsTapToPay() else {
            return .unavailable(reason: .deviceNotSupported)
        }
        guard siteIsEligibleForTapToPay() else {
            return .unavailable(reason: .siteNotEligible)
        }
        return .available
    }
}

private extension POSTapToPayAvailabilityChecker {
    /// True when the store's country has Tap to Pay in its `CardPresentPaymentsConfiguration`
    /// supported readers list. Today on iOS that's US and GB only — every other country
    /// either has external readers only (CA, PR, EEA, SG, NZ, AU) or no card support at all
    /// (BR, JP, MX, IN, …). Without this gate the TTP hero would render on iPhone in any
    /// country that has POS visibility cached, including non-TTP countries like Spain.
    ///
    /// Fails closed when `configurationLoader` returns nil — there's no payment
    /// configuration to read supported readers from, so we cannot honestly claim
    /// TTP support, period.
    func countrySupportsTapToPay() -> Bool {
        guard let configuration = configurationLoader() else { return false }
        return configuration.supportedReaders.contains(.tapToPay)
    }

    func deviceSupportsTapToPay() async -> Bool {
        // `StoresManager.dispatch` asserts main-thread; `withCheckedContinuation`'s
        // closure runs on whatever thread the awaiter is on, which after a prior
        // suspension point may be a cooperative background thread. Hop to the main
        // actor before dispatching.
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                let action = CardPresentPaymentAction.checkDeviceSupport(
                    siteID: siteID,
                    cardReaderType: .tapToPay,
                    discoveryMethod: .tapToPay,
                    minimumOperatingSystemVersionOverride: nil
                ) { isSupported in
                    continuation.resume(returning: isSupported)
                }
                stores.dispatch(action)
            }
        }
    }

    /// Defensive: POS visibility cache must be populated for this site. With universal
    /// POS this is true once `POSTabVisibilityChecker` has run at least once for the
    /// site, so it's mainly a guard against cold-start race conditions rather than a
    /// country/IPP gate (those are checked above).
    func siteIsEligibleForTapToPay() -> Bool {
        eligibilityService.loadCachedPOSTabVisibility(siteID: siteID) ?? false
    }
}
