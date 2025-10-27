import Foundation
import CocoaLumberjackSwift

@MainActor
public final class POSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    private let siteID: Int64
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol
    private let catalogSizeLimit: Int
    private let isLocalCatalogFeatureFlagEnabled: Bool
    private var isPOSTabVisible: Bool

    // Current eligibility state
    public private(set) var eligibilityState: POSLocalCatalogEligibilityState

    /// Initialize eligibility service
    /// Note: Call refreshEligibilityState() after creation to perform initial check
    public init(
        siteID: Int64,
        catalogSizeChecker: POSCatalogSizeCheckerProtocol,
        isLocalCatalogFeatureFlagEnabled: Bool,
        isPOSTabVisible: Bool,
        catalogSizeLimit: Int? = nil
    ) {
        self.siteID = siteID
        self.catalogSizeChecker = catalogSizeChecker
        self.isLocalCatalogFeatureFlagEnabled = isLocalCatalogFeatureFlagEnabled
        self.isPOSTabVisible = isPOSTabVisible
        self.catalogSizeLimit = catalogSizeLimit ?? Constants.defaultCatalogSizeLimit
        // Start with eligible state, will be updated on first refresh
        self.eligibilityState = .eligible
    }

    /// Update the visibility state and refresh eligibility
    public func updateVisibility(isPOSTabVisible: Bool) async {
        self.isPOSTabVisible = isPOSTabVisible
        await refreshEligibilityState()
    }

    @discardableResult
    public func refreshEligibilityState() async -> POSLocalCatalogEligibilityState {
        // Check POS tab visibility FIRST - no point in checking catalog if POS tab isn't visible
        guard isPOSTabVisible else {
            eligibilityState = .ineligible(reason: .posTabNotVisible)
            DDLogInfo("📋 POSLocalCatalogEligibilityService: POS tab not visible for site \(siteID)")
            return eligibilityState
        }

        // Check feature flag - if disabled, no need to check catalog size
        guard isLocalCatalogFeatureFlagEnabled else {
            eligibilityState = .ineligible(reason: .featureFlagDisabled)
            DDLogInfo("📋 POSLocalCatalogEligibilityService: Local catalog feature flag disabled for site \(siteID)")
            return eligibilityState
        }

        // Fetch remote catalog size and check against limit
        do {
            let size = try await catalogSizeChecker.checkCatalogSize(for: siteID)

            if size.totalCount > catalogSizeLimit {
                eligibilityState = .ineligible(
                    reason: .catalogSizeTooLarge(totalCount: size.totalCount, limit: catalogSizeLimit)
                )
                DDLogInfo("📋 POSLocalCatalogEligibilityService: Site \(siteID) catalog size \(size.totalCount) exceeds limit \(catalogSizeLimit)")
                return eligibilityState
            }

            DDLogInfo("📋 POSLocalCatalogEligibilityService: Site \(siteID) catalog size \(size.totalCount) is within limit \(catalogSizeLimit)")
            eligibilityState = .eligible
            return eligibilityState

        } catch {
            let errorString = String(describing: error)
            eligibilityState = .ineligible(
                reason: .catalogSizeCheckFailed(underlyingError: errorString)
            )
            DDLogError("📋 POSLocalCatalogEligibilityService: Failed to check catalog size for site \(siteID): \(error)")
            return eligibilityState
        }
    }

    // MARK: - POSCatalogEligibilityChecking

    nonisolated public func isCatalogEligibleForSync() async -> Bool {
        await refreshEligibilityState() == .eligible
    }
}

// MARK: - Constants

private extension POSLocalCatalogEligibilityService {
    enum Constants {
        static let defaultCatalogSizeLimit = 1000
    }
}
