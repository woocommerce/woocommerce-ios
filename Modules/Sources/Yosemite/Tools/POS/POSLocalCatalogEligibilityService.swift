import Foundation
import Alamofire
import WooFoundationCore

public actor POSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol
    private let systemStatusService: POSSystemStatusServiceProtocol
    private let catalogSizeLimit: Int
    private let isLocalCatalogFeatureFlagEnabled: Bool
    private let isCatalogAPIFeatureFlagEnabled: Bool
    private let remoteFeatureFlagProvider: @Sendable () async -> Bool
    private let betaFeatureToggleProvider: @Sendable () async -> Bool

    // Eligibility states cached per site
    private var eligibilityStates: [Int64: POSLocalCatalogEligibilityState] = [:]

    // POS eligibility states cached per site
    private var posEligibilityStates: [Int64: Bool] = [:]

    // Cached remote feature flag value
    private var cachedRemoteFeatureFlag: Bool?

    /// Initialize eligibility service
    /// - Parameters:
    ///   - catalogSizeChecker: Service to check catalog size for sites
    ///   - systemStatusService: Service to check WooCommerce plugin version
    ///   - isLocalCatalogFeatureFlagEnabled: Whether the local catalog feature flag is enabled
    ///   - remoteFeatureFlagProvider: Async closure that fetches the remote feature flag value
    ///   - betaFeatureToggleProvider: Async closure that fetches the beta feature toggle value from app settings
    ///   - catalogSizeLimit: Maximum allowed catalog size (products + variations)
    public init(
        catalogSizeChecker: POSCatalogSizeCheckerProtocol,
        systemStatusService: POSSystemStatusServiceProtocol,
        isLocalCatalogFeatureFlagEnabled: Bool,
        isCatalogAPIFeatureFlagEnabled: Bool = false,
        remoteFeatureFlagProvider: @escaping @Sendable () async -> Bool,
        betaFeatureToggleProvider: @escaping @Sendable () async -> Bool,
        catalogSizeLimit: Int? = nil
    ) {
        self.catalogSizeChecker = catalogSizeChecker
        self.systemStatusService = systemStatusService
        self.isLocalCatalogFeatureFlagEnabled = isLocalCatalogFeatureFlagEnabled
        self.isCatalogAPIFeatureFlagEnabled = isCatalogAPIFeatureFlagEnabled
        self.remoteFeatureFlagProvider = remoteFeatureFlagProvider
        self.betaFeatureToggleProvider = betaFeatureToggleProvider
        self.catalogSizeLimit = catalogSizeLimit ?? Constants.defaultCatalogSizeLimit
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
        // Store the POS eligibility state for this site
        posEligibilityStates[siteID] = isEligible
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

        // Check WooCommerce version:
        // - Paginated sync requires 10.3.0+
        // - Catalog API requires 10.5.0+,
        let minimumVersion = isCatalogAPIFeatureFlagEnabled ? Constants.wcPluginMinimumVersionForCatalogAPI : Constants.wcPluginMinimumVersionForLocalCatalog
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
        } catch AFError.explicitlyCancelled, is CancellationError {
            throw POSCatalogSyncError.requestCancelled
        } catch {
            let errorString = String(describing: error)
            let state = POSLocalCatalogEligibilityState.ineligible(
                reason: .catalogSizeCheckFailed(underlyingError: errorString)
            )
            eligibilityStates[siteID] = state
            DDLogError("📋 POSLocalCatalogEligibilityService: Failed to check WooCommerce version for site \(siteID): \(error)")
            return state
        }

        // Catalog API supports stores of any size, so we skip the size check
        if isCatalogAPIFeatureFlagEnabled {
            DDLogInfo("📋 POSLocalCatalogEligibilityService: Using catalog API, skipping size check for site \(siteID)")
            eligibilityStates[siteID] = .eligible
            return .eligible
        }

        // Fetch remote catalog size and check against limit (paginated sync only)
        // Once pointOfSaleCatalogAPI is enabled and file approach is working, catalog size won't apply
        do {
            let size = try await catalogSizeChecker.checkCatalogSize(for: siteID)

            if size.totalCount > catalogSizeLimit {
                let state = POSLocalCatalogEligibilityState.ineligible(
                    reason: .catalogSizeTooLarge(totalCount: size.totalCount, limit: catalogSizeLimit)
                )
                eligibilityStates[siteID] = state
                DDLogInfo("📋 POSLocalCatalogEligibilityService: Site \(siteID) catalog size \(size.totalCount) exceeds limit \(catalogSizeLimit)")
                return state
            }

            DDLogInfo("📋 POSLocalCatalogEligibilityService: Site \(siteID) catalog size \(size.totalCount) is within limit \(catalogSizeLimit)")
            eligibilityStates[siteID] = .eligible
            return .eligible
        } catch AFError.explicitlyCancelled, is CancellationError {
            throw POSCatalogSyncError.requestCancelled
        } catch {
            let errorString = String(describing: error)
            let state = POSLocalCatalogEligibilityState.ineligible(
                reason: .catalogSizeCheckFailed(underlyingError: errorString)
            )
            eligibilityStates[siteID] = state
            DDLogError("📋 POSLocalCatalogEligibilityService: Failed to check catalog size for site \(siteID): \(error)")
            return state
        }
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
        static let defaultCatalogSizeLimit = 1000
        static let wcPluginMinimumVersionForLocalCatalog = "10.3.0-beta"
        static let wcPluginMinimumVersionForCatalogAPI = "10.5.0"
    }
}
