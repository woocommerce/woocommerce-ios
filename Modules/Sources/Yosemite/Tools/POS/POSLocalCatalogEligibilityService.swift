import Foundation
import CocoaLumberjackSwift

public actor POSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol
    private let catalogSizeLimit: Int
    private let isLocalCatalogFeatureFlagEnabled: Bool

    // Eligibility states cached per site
    private var eligibilityStates: [Int64: POSLocalCatalogEligibilityState] = [:]

    // POS eligibility states cached per site
    private var posEligibilityStates: [Int64: Bool] = [:]

    /// Initialize eligibility service
    /// - Parameters:
    ///   - catalogSizeChecker: Service to check catalog size for sites
    ///   - isLocalCatalogFeatureFlagEnabled: Whether the local catalog feature flag is enabled
    ///   - catalogSizeLimit: Maximum allowed catalog size (products + variations)
    public init(
        catalogSizeChecker: POSCatalogSizeCheckerProtocol,
        isLocalCatalogFeatureFlagEnabled: Bool,
        catalogSizeLimit: Int? = nil
    ) {
        self.catalogSizeChecker = catalogSizeChecker
        self.isLocalCatalogFeatureFlagEnabled = isLocalCatalogFeatureFlagEnabled
        self.catalogSizeLimit = catalogSizeLimit ?? Constants.defaultCatalogSizeLimit
    }

    /// Get catalog eligibility for a specific site
    /// If not cached, refreshes eligibility and returns the result
    public func catalogEligibility(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
        if let cached = eligibilityStates[siteID] {
            return cached
        }
        // Not cached yet, refresh and return
        return await refreshEligibilityState(for: siteID)
    }

    /// Update POS eligibility and refresh catalog eligibility for the specified site
    /// - Parameters:
    ///   - isEligible: Whether POS is eligible
    ///   - siteID: The site ID to refresh eligibility for
    public func updatePOSEligibility(isEligible: Bool, for siteID: Int64) async {
        // Store the POS eligibility state for this site
        posEligibilityStates[siteID] = isEligible
        // Refresh eligibility for the current site now that POS eligibility has changed
        await refreshEligibilityState(for: siteID)
    }

    /// Refresh eligibility state for a specific site
    @discardableResult
    public func refreshEligibilityState(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
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

        // Check feature flag - if disabled, no need to check catalog size
        guard isLocalCatalogFeatureFlagEnabled else {
            let state = POSLocalCatalogEligibilityState.ineligible(reason: .featureFlagDisabled)
            eligibilityStates[siteID] = state
            DDLogInfo("📋 POSLocalCatalogEligibilityService: Local catalog feature flag disabled for site \(siteID)")
            return state
        }

        // Fetch remote catalog size and check against limit
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
}

// MARK: - Constants

private extension POSLocalCatalogEligibilityService {
    enum Constants {
        static let defaultCatalogSizeLimit = 1000
    }
}
