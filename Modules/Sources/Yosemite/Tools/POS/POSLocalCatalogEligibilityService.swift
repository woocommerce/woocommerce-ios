import Foundation
import Alamofire
import WooFoundationCore

public actor POSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    private let systemStatusService: POSSystemStatusServiceProtocol
    private let isLocalCatalogFeatureFlagEnabled: Bool
    private let isCatalogAPIFeatureFlagEnabled: Bool
    private let remoteFeatureFlagProvider: @Sendable () async -> Bool
    private let betaFeatureToggleProvider: @Sendable () async -> Bool
    private let syncStatusChecker: POSCatalogSyncStatusCheckerProtocol?

    // Eligibility states cached per site
    private var eligibilityStates: [Int64: POSLocalCatalogEligibilityState] = [:]

    // POS eligibility states cached per site
    private var posEligibilityStates: [Int64: Bool] = [:]

    // Cached remote feature flag value
    private var cachedRemoteFeatureFlag: Bool?

    /// Initialize eligibility service
    /// - Parameters:
    ///   - systemStatusService: Service to check WooCommerce plugin version
    ///   - isLocalCatalogFeatureFlagEnabled: Whether the local catalog feature flag is enabled
    ///   - remoteFeatureFlagProvider: Async closure that fetches the remote feature flag value
    ///   - betaFeatureToggleProvider: Async closure that fetches the beta feature toggle value from app settings
    ///   - syncStatusChecker: Checks whether a full catalog sync completed for a site.
    ///     Used to keep the local catalog usable when remote eligibility checks fail (e.g. offline).
    public init(
        systemStatusService: POSSystemStatusServiceProtocol,
        isLocalCatalogFeatureFlagEnabled: Bool,
        isCatalogAPIFeatureFlagEnabled: Bool = false,
        remoteFeatureFlagProvider: @escaping @Sendable () async -> Bool,
        betaFeatureToggleProvider: @escaping @Sendable () async -> Bool,
        syncStatusChecker: POSCatalogSyncStatusCheckerProtocol? = nil
    ) {
        self.systemStatusService = systemStatusService
        self.isLocalCatalogFeatureFlagEnabled = isLocalCatalogFeatureFlagEnabled
        self.isCatalogAPIFeatureFlagEnabled = isCatalogAPIFeatureFlagEnabled
        self.remoteFeatureFlagProvider = remoteFeatureFlagProvider
        self.betaFeatureToggleProvider = betaFeatureToggleProvider
        self.syncStatusChecker = syncStatusChecker
        // Eagerly start fetching the remote flag in the background
        Task {
            await self.fetchRemoteFlag()
        }
    }

    /// Get catalog eligibility for a specific site
    /// If not cached, refreshes eligibility and returns the result
    public func catalogEligibility(for siteID: Int64) async throws -> POSLocalCatalogEligibilityState {
        guard await betaFeatureToggleProvider() else {
            // If the user changes the toggle, we should respond to that immediately, ignoring the cache. It's cheap to check.
            DDLogInfo("📋 POSLocalCatalogEligibilityService: Local catalog beta toggle disabled for site \(siteID)")
            return .ineligible(reason: .featureFlagDisabled)
        }

        if let cached = eligibilityStates[siteID] {
            return cached
        }
        // Not cached yet, refresh and return
        return try await refreshEligibilityState(for: siteID)
    }

    /// The cached state without evaluating: `catalogEligibility(for:)` refreshes on a miss, which can fetch.
    public func cachedCatalogEligibility(for siteID: Int64) -> POSLocalCatalogEligibilityState? {
        eligibilityStates[siteID]
    }

    /// Fetch and cache the remote feature flag value
    /// Returns cached value if available, otherwise returns true (assumes eligible)
    private func isRemoteCatalogFeatureFlagEnabled() async -> Bool {
        // Return cached value if we have one
        return cachedRemoteFeatureFlag ?? true
    }

    /// Fetch the remote feature flag value and cache it (actor-isolated)
    private func fetchRemoteFlag() async {
        let value = await remoteFeatureFlagProvider()
        cachedRemoteFeatureFlag = value
    }

    /// Update POS eligibility and refresh catalog eligibility for the specified site
    /// - Parameters:
    ///   - isEligible: Whether POS is eligible
    ///   - siteID: The site ID to refresh eligibility for
    public func updatePOSEligibility(isEligible: Bool, for siteID: Int64) async throws {
        let previousEligibility = posEligibilityStates[siteID]
        // Store the POS eligibility state for this site
        posEligibilityStates[siteID] = isEligible

        // When nothing changed and an eligible state is already cached, keep it so POS entry
        // (like Android) doesn't wait on remote re-checks that a previous refresh already ran.
        // Cached ineligible states always re-validate, so recoverable conditions (e.g. the beta
        // toggle turning on, or a transient check failure) are picked up without an app restart.
        if previousEligibility == isEligible, eligibilityStates[siteID] == .eligible {
            return
        }

        // Refresh eligibility for the current site now that POS eligibility has changed
        try await refreshEligibilityState(for: siteID)
    }

    /// Refresh eligibility state for a specific site
    @discardableResult
    public func refreshEligibilityState(for siteID: Int64) async throws -> POSLocalCatalogEligibilityState {
        // Check POS tab eligibility FIRST - no point in checking catalog if POS isn't eligible
        guard let isPOSEligible = posEligibilityStates[siteID] else {
            // We don't have POS eligibility info yet - don't cache this state
            // Return ineligible but allow it to be refreshed later when eligibility is known
            let state = POSLocalCatalogEligibilityState.ineligible(reason: .posTabNotEligible)
            DDLogInfo("📋 POSLocalCatalogEligibilityService: POS eligibility unknown for site \(siteID), assuming ineligible")
            return state
        }

        guard isPOSEligible else {
            // We know POS is explicitly ineligible - cache this state
            let state = POSLocalCatalogEligibilityState.ineligible(reason: .posTabNotEligible)
            eligibilityStates[siteID] = state
            DDLogInfo("📋 POSLocalCatalogEligibilityService: POS not eligible for site \(siteID)")
            return state
        }

        let (isLocalCatalogFeatureFlagEnabled, isRemoteEnabled, isBetaToggleEnabled) = await featureFlagSettings()
        guard isLocalCatalogFeatureFlagEnabled, isRemoteEnabled, isBetaToggleEnabled else {
            let state = POSLocalCatalogEligibilityState.ineligible(reason: .featureFlagDisabled)
            eligibilityStates[siteID] = state
            DDLogInfo("📋 POSLocalCatalogEligibilityService: Local catalog feature flags disabled for site \(siteID) " +
                      "(local: \(isLocalCatalogFeatureFlagEnabled), remote: \(isRemoteEnabled), betaToggle: \(isBetaToggleEnabled))")
            return state
        }

        // Check WooCommerce version: local catalog requires 10.5.0+ (Catalog API)
        let minimumVersion = Constants.wcPluginMinimumVersionForLocalCatalog
        do {
            let pluginInfo = try await systemStatusService.loadWooCommercePluginAndPOSFeatureSwitch(siteID: siteID)

            guard let wcPlugin = pluginInfo.wcPlugin, wcPlugin.active else {
                let state = POSLocalCatalogEligibilityState.ineligible(reason: .posTabNotEligible)
                eligibilityStates[siteID] = state
                DDLogInfo("📋 POSLocalCatalogEligibilityService: WooCommerce plugin not found or inactive for site \(siteID)")
                return state
            }

            guard VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                    minimumRequired: minimumVersion) else {
                let state = POSLocalCatalogEligibilityState.ineligible(
                    reason: .unsupportedWooCommerceVersion(minimumVersion: minimumVersion)
                )
                eligibilityStates[siteID] = state
                DDLogInfo("📋 POSLocalCatalogEligibilityService: WooCommerce version \(wcPlugin.version) below minimum " +
                          "\(minimumVersion) for site \(siteID)")
                return state
            }

            DDLogInfo("📋 POSLocalCatalogEligibilityService: WooCommerce version \(wcPlugin.version) meets minimum requirement for site \(siteID)")
            eligibilityStates[siteID] = .eligible
            return .eligible
        } catch AFError.explicitlyCancelled, is CancellationError {
            throw POSCatalogSyncError.requestCancelled
        } catch {
            // Loading the plugin info for the version check failed (e.g. offline or a server
            // error) — the version itself could not be determined. A completed full sync implies
            // the version requirement was met when the catalog was synced, so this should not
            // drop POS to remote mode. The tolerant result is not cached so the next refresh
            // re-validates.
            if await syncStatusChecker?.hasCompletedFullSync(for: siteID) == true {
                DDLogInfo("📋 POSLocalCatalogEligibilityService: Failed to load plugin info for the version check " +
                          "for site \(siteID), using previously synced catalog: \(error)")
                return .eligible
            }
            let errorString = String(describing: error)
            let state = POSLocalCatalogEligibilityState.ineligible(
                reason: .versionCheckFailed(underlyingError: errorString)
            )
            eligibilityStates[siteID] = state
            DDLogError("📋 POSLocalCatalogEligibilityService: Failed to check WooCommerce version for site \(siteID): \(error)")
            return state
        }
    }

    /// Whether the local catalog feature is enabled based on locally available signals only.
    public func isLocalCatalogFeatureEnabled() async -> Bool {
        let (isLocalEnabled, isRemoteEnabled, isBetaToggleEnabled) = await featureFlagSettings()
        return isLocalEnabled && isRemoteEnabled && isBetaToggleEnabled
    }

    private func featureFlagSettings() async -> (Bool, Bool, Bool) {
        // Check feature flags - local, remote, and beta toggle must all be enabled
        let isRemoteEnabled = await isRemoteCatalogFeatureFlagEnabled()
        let isBetaToggleEnabled = await betaFeatureToggleProvider()
        return (isLocalCatalogFeatureFlagEnabled, isRemoteEnabled, isBetaToggleEnabled)
    }
}

// MARK: - Factory Method

public extension POSLocalCatalogEligibilityService {
    /// Creates a remote feature flag provider closure for POS local catalog
    /// - Parameter dispatcher: The dispatcher to use for fetching the remote flag
    /// - Returns: A closure that fetches the remote feature flag value, defaulting to true if unavailable
    static func makeRemoteFeatureFlagProvider(dispatcher: Dispatcher) -> @Sendable () async -> Bool {
        return {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(.posLocalCatalogM1, defaultValue: true) { isEnabled in
                        continuation.resume(returning: isEnabled)
                    }
                    dispatcher.dispatch(action)
                }
            }
        }
    }
}

// MARK: - Constants

private extension POSLocalCatalogEligibilityService {
    enum Constants {
        static let wcPluginMinimumVersionForLocalCatalog = "10.5.0"
    }
}
