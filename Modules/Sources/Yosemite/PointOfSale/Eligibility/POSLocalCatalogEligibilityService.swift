import Foundation
import CocoaLumberjackSwift

/// Service that provides eligibility information for local catalog feature
///
/// Other services can query this for eligibility state and reasons:
/// - Sync coordinator can check if catalog is eligible
/// - Settings UI can display eligibility status and reasons
/// - Analytics can track why stores are ineligible
///
/// NOTE: This service checks catalog-related eligibility (size limits) and feature flag state.
/// Feature flag value is captured at initialization and won't change during service lifetime.
public protocol POSLocalCatalogEligibilityServiceProtocol {
    /// Get eligibility state
    /// - Returns: Eligibility state with reason if ineligible
    func getEligibilityState() async -> POSLocalCatalogEligibilityState

    /// Force refresh eligibility (bypasses cache)
    /// - Returns: Fresh eligibility state with reason if ineligible
    func refreshEligibilityState() async -> POSLocalCatalogEligibilityState
}

public actor POSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    private let siteID: Int64
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol
    private let catalogSizeLimit: Int
    private let isFeatureFlagEnabled: Bool

    // Cached eligibility state
    private var cachedState: POSLocalCatalogEligibilityState?

    public init(
        siteID: Int64,
        catalogSizeChecker: POSCatalogSizeCheckerProtocol,
        isFeatureFlagEnabled: Bool,
        catalogSizeLimit: Int? = nil
    ) {
        self.siteID = siteID
        self.catalogSizeChecker = catalogSizeChecker
        self.isFeatureFlagEnabled = isFeatureFlagEnabled
        self.catalogSizeLimit = catalogSizeLimit ?? Constants.defaultCatalogSizeLimit
    }

    public func getEligibilityState() async -> POSLocalCatalogEligibilityState {
        // Return cached if available
        if let cached = cachedState {
            return cached
        }

        return await refreshEligibilityState()
    }

    public func refreshEligibilityState() async -> POSLocalCatalogEligibilityState {
        // Check feature flag first - if disabled, no need to check catalog size
        guard isFeatureFlagEnabled else {
            let state: POSLocalCatalogEligibilityState = .ineligible(reason: .featureFlagDisabled)
            cachedState = state
            return state
        }

        // Fetch remote catalog size and check against limit
        do {
            let size = try await catalogSizeChecker.checkCatalogSize(for: siteID)

            if size.totalCount > catalogSizeLimit {
                let state: POSLocalCatalogEligibilityState = .ineligible(
                    reason: .catalogSizeTooLarge(totalCount: size.totalCount, limit: catalogSizeLimit)
                )
                DDLogInfo("📋 POSLocalCatalogEligibilityService: Site \(siteID) catalog size \(size.totalCount) exceeds limit \(catalogSizeLimit)")
                cachedState = state
                return state
            }

            DDLogInfo("📋 POSLocalCatalogEligibilityService: Site \(siteID) catalog size \(size.totalCount) is within limit \(catalogSizeLimit)")
            let state: POSLocalCatalogEligibilityState = .eligible
            cachedState = state
            return state

        } catch {
            let errorString = String(describing: error)
            let state: POSLocalCatalogEligibilityState = .ineligible(
                reason: .catalogSizeCheckFailed(underlyingError: errorString)
            )
            DDLogError("📋 POSLocalCatalogEligibilityService: Failed to check catalog size for site \(siteID): \(error)")
            cachedState = state
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
