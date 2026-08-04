import Foundation
import UIKit
import PointOfSale
import enum Experiments.FeatureFlag
import protocol Experiments.FeatureFlagService
import enum Yosemite.CardPresentPaymentAction
import enum Yosemite.CardReaderDiscoveryMethod
import enum Hardware.CardReaderType
import protocol Yosemite.StoresManager
import protocol Yosemite.POSEligibilityServiceProtocol

/// Resolves Tap to Pay availability for the current POS session.
///
/// Four gates, evaluated in order — fail fast on whichever is first to deny:
/// 1. Device idiom — POS Tap to Pay is phone-only. iPad POS keeps its Bluetooth-primary
///    flow, so we deny statically rather than paying for the async device-support check.
/// 2. The `pointOfSaleTapToPay` feature flag (cheapest remaining check, shortcuts the rest).
/// 3. Device support — Stripe's `Terminal.shared.supportsReaders(of: .appleBuiltIn, ...)`,
///    dispatched via `CardPresentPaymentAction.checkDeviceSupport`.
/// 4. Site eligibility — proxied off cached POS tab visibility, which is itself driven
///    by IPP/country eligibility checks in `POSTabVisibilityChecker`.
///
/// One-shot — `POSTapToPayAvailabilityController` calls `checkAvailability()` once on
/// POS entry and holds the result for the rest of the session.
final class POSTapToPayAvailabilityChecker: POSTapToPayAvailabilityChecking {
    private let siteID: Int64
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let eligibilityService: POSEligibilityServiceProtocol
    private let userInterfaceIdiom: UIUserInterfaceIdiom

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         eligibilityService: POSEligibilityServiceProtocol,
         userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        self.siteID = siteID
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.eligibilityService = eligibilityService
        self.userInterfaceIdiom = userInterfaceIdiom
    }

    func checkAvailability() async -> POSTapToPayAvailabilityState {
        guard userInterfaceIdiom == .phone else {
            return .unavailable(reason: .deviceNotSupported)
        }
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleTapToPay) else {
            return .unavailable(reason: .featureFlagDisabled)
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

    /// POS only renders when the site is IPP-eligible (see `POSTabVisibilityChecker`),
    /// and the result is cached per-site once that check runs. Reusing it here avoids a
    /// duplicate eligibility roundtrip on every POS entry.
    func siteIsEligibleForTapToPay() -> Bool {
        eligibilityService.loadCachedPOSTabVisibility(siteID: siteID) ?? false
    }
}
