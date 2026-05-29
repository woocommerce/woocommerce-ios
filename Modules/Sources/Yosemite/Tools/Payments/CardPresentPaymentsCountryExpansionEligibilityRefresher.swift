import Foundation
import enum WooFoundation.CountryCode

/// Refreshes the cached In-Person Payments country eligibility for countries gated by
/// remote flags. Maps the site's country to the relevant remote feature flag, fetches
/// the latest value via the supplied provider, and writes it back through
/// ``CardPresentPaymentsCountryExpansionEligibilityServiceProtocol``.
/// Australia uses a separate WooPayments-only remote flag.
///
/// US/PR/CA/GB short-circuit to `true` without any flag dispatch.
public final class CardPresentPaymentsCountryExpansionEligibilityRefresher: @unchecked Sendable {
    private let eligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
    private let remoteFeatureFlagProvider: @Sendable (RemoteFeatureFlag) async -> Bool

    public init(
        eligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol = CardPresentPaymentsCountryExpansionEligibilityService(),
        remoteFeatureFlagProvider: @escaping @Sendable (RemoteFeatureFlag) async -> Bool
    ) {
        self.eligibilityService = eligibilityService
        self.remoteFeatureFlagProvider = remoteFeatureFlagProvider
    }

    /// Refreshes the cached eligibility for `siteID` based on `countryCode`.
    /// Existing IPP countries (US/PR/CA/GB) short-circuit to `true`.
    /// Gated countries dispatch the relevant remote feature flag and persist the result.
    public func refresh(siteID: Int64, countryCode: CountryCode) async {
        guard let flag = Self.flag(for: countryCode) else {
            // Either an existing supported country or one we don't know about — short-circuit.
            // For existing supported countries we want eligibility = true so they keep working.
            // For unknown countries the eligibility flag is irrelevant (the country lookup will
            // fail at the configuration level), so returning `true` is harmless.
            eligibilityService.cacheEligibility(siteID: siteID, isEligible: true)
            return
        }
        let isEnabled = await remoteFeatureFlagProvider(flag)
        eligibilityService.cacheEligibility(siteID: siteID, isEligible: isEnabled)
    }

    /// Returns the remote feature flag that gates IPP for the given country, if any.
    /// Returns `nil` for the existing supported countries (US/PR/CA/GB), which need no flag.
    public static func flag(for country: CountryCode) -> RemoteFeatureFlag? {
        switch country {
        case .US, .PR, .CA, .GB:
            return nil
        case .FR, .DE, .IE, .NL, .SG, .NZ:
            return .inPersonPaymentsCountryExpansion
        case .AT, .BE, .FI, .IT, .LU, .PT, .ES:
            return .inPersonPaymentsCountryExpansionEUExtended
        case .AU:
            return .inPersonPaymentsAustraliaWooPayments
        default:
            return nil
        }
    }
}

// MARK: - Factory

public extension CardPresentPaymentsCountryExpansionEligibilityRefresher {
    /// Builds a `(RemoteFeatureFlag) async -> Bool` provider that dispatches a
    /// `FeatureFlagAction` against the supplied stores. Gated countries default
    /// to enabled, with remote flags available as off switches.
    static func makeRemoteFeatureFlagProvider(stores: StoresManager) -> @Sendable (RemoteFeatureFlag) async -> Bool {
        return { flag in
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(
                        flag,
                        defaultValue: true
                    ) { isEnabled in
                        continuation.resume(returning: isEnabled)
                    }
                    stores.dispatch(action)
                }
            }
        }
    }
}
