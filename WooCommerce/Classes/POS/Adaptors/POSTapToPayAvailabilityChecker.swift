import Foundation
import PointOfSale
import ProximityReader
import enum Yosemite.CardPresentPaymentAction
import enum Yosemite.CardReaderDiscoveryMethod
import enum Hardware.CardReaderType
import enum WooFoundation.CountryCode
import struct Yosemite.CardPresentPaymentsConfiguration
import protocol Yosemite.StoresManager
import protocol Yosemite.POSEligibilityServiceProtocol

/// Resolves Tap to Pay availability for the current POS session.
///
/// Three gates, evaluated in order — fail fast on whichever is first to deny:
/// 1. Hardware support — Apple's `PaymentCardReader.isSupported`.
/// 2. Site eligibility — the store country must support Tap to Pay, and the cached POS tab
///    visibility (driven by IPP/country eligibility checks in `POSTabVisibilityChecker`) must be true.
/// 3. Device support — Stripe's `Terminal.shared.supportsReaders(of: .appleBuiltIn, ...)`,
///    dispatched via `CardPresentPaymentAction.checkDeviceSupport`.
///
/// One-shot — `POSTapToPayAvailabilityController` calls `checkAvailability()` once on
/// POS entry and holds the result for the rest of the session.
@MainActor
final class POSTapToPayAvailabilityChecker: POSTapToPayAvailabilityChecking {
    private let siteID: Int64
    private let countryCode: CountryCode
    private let stores: StoresManager
    private let eligibilityService: POSEligibilityServiceProtocol
    private let isTapToPayHardwareSupported: Bool

    init(siteID: Int64,
         countryCode: CountryCode,
         stores: StoresManager = ServiceLocator.stores,
         eligibilityService: POSEligibilityServiceProtocol,
         isTapToPayHardwareSupported: Bool = PaymentCardReader.isSupported) {
        self.siteID = siteID
        self.countryCode = countryCode
        self.stores = stores
        self.eligibilityService = eligibilityService
        self.isTapToPayHardwareSupported = isTapToPayHardwareSupported
    }

    func checkAvailability() async -> POSTapToPayAvailabilityState {
        guard isTapToPayHardwareSupported else {
            return .unavailable(reason: .deviceNotSupported)
        }
        guard siteIsEligibleForTapToPay() else {
            return .unavailable(reason: .siteNotEligible)
        }
        guard await deviceSupportsTapToPay() else {
            return .unavailable(reason: .deviceNotSupported)
        }
        return .available
    }
}

private extension POSTapToPayAvailabilityChecker {
    func deviceSupportsTapToPay() async -> Bool {
        // `withCheckedContinuation` runs its body synchronously on the caller's isolation,
        // so the dispatch happens on the main actor as `StoresManager.dispatch` requires.
        await withCheckedContinuation { continuation in
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

    /// POS is open in countries where Tap to Pay is not supported (e.g. PR, CA, AU), so POS
    /// eligibility alone is not enough. The cached POS tab visibility avoids a duplicate
    /// eligibility roundtrip on every POS entry.
    func siteIsEligibleForTapToPay() -> Bool {
        guard CardPresentPaymentsConfiguration(country: countryCode).supportedReaders.contains(.tapToPay) else {
            return false
        }
        return eligibilityService.loadCachedPOSTabVisibility(siteID: siteID) ?? false
    }
}
