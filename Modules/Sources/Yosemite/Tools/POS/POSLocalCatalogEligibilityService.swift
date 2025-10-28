import Foundation
import CocoaLumberjackSwift

public actor POSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol
    private let catalogSizeLimit: Int
    private let isLocalCatalogFeatureFlagEnabled: Bool
    private var isPOSTabVisible: Bool

    // Eligibility states cached per site
    private var eligibilityStates: [Int64: POSLocalCatalogEligibilityState] = [:]

    /// Initialize eligibility service
    public init(
        catalogSizeChecker: POSCatalogSizeCheckerProtocol,
        isLocalCatalogFeatureFlagEnabled: Bool,
        isPOSTabVisible: Bool,
        catalogSizeLimit: Int? = nil
    ) {
        self.catalogSizeChecker = catalogSizeChecker
        self.isLocalCatalogFeatureFlagEnabled = isLocalCatalogFeatureFlagEnabled
        self.isPOSTabVisible = isPOSTabVisible
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

    /// Update the POS tab visibility state and refresh eligibility for the specified site
    public func updateVisibility(isPOSTabVisible: Bool, for siteID: Int64) async {
        self.isPOSTabVisible = isPOSTabVisible
        // Refresh eligibility for the current site now that visibility has changed
        await refreshEligibilityState(for: siteID)
    }

    /// Refresh eligibility state for a specific site
    @discardableResult
    public func refreshEligibilityState(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
        // Check POS tab visibility FIRST - no point in checking catalog if POS tab isn't visible
        guard isPOSTabVisible else {
            let state = POSLocalCatalogEligibilityState.ineligible(reason: .posTabNotVisible)
            eligibilityStates[siteID] = state
            DDLogInfo("📋 POSLocalCatalogEligibilityService: POS tab not visible for site \(siteID)")
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
