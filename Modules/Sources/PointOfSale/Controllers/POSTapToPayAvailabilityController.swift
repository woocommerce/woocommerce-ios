import Foundation
import Observation
import WooFoundationCore

/// Owns the resolved Tap to Pay availability state for the POS session and exposes it
/// to views. Kicks off a single async check on init via the injected checker, then holds
/// the result for the rest of the session.
///
/// Designed so future PRs can read `state` to gate UI (multi-method buttons row,
/// pre-connect on checkout, etc.) without each view re-running the eligibility check.
@Observable @MainActor public final class POSTapToPayAvailabilityController {
    public private(set) var state: POSTapToPayAvailabilityState = .unknown

    private let availabilityChecker: POSTapToPayAvailabilityChecking
    private let analytics: POSAnalyticsProviding?

    public init(availabilityChecker: POSTapToPayAvailabilityChecking,
                analytics: POSAnalyticsProviding? = nil) {
        self.availabilityChecker = availabilityChecker
        self.analytics = analytics

        Task { @MainActor in
            let resolved = await availabilityChecker.checkAvailability()
            self.state = resolved
            self.trackResolved(resolved)
        }
    }

    private func trackResolved(_ state: POSTapToPayAvailabilityState) {
        guard case .unavailable(let reason) = state else { return }
        analytics?.track(.pointOfSaleTapToPayNotAvailable,
                         parameters: ["reason": reason.rawValue])
    }
}

public extension POSTapToPayAvailabilityState {
    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }
}
