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
/// The service performs an initial eligibility check during initialization.
public protocol POSLocalCatalogEligibilityServiceProtocol {
    /// Current eligibility state (synchronously accessible on main thread)
    var eligibilityState: POSLocalCatalogEligibilityState { get }

    /// Force refresh eligibility (bypasses cache and updates eligibilityState)
    /// - Returns: Fresh eligibility state with reason if ineligible
    func refreshEligibilityState() async -> POSLocalCatalogEligibilityState
}

@MainActor
public final class POSLocalCatalogEligibilityService: @MainActor POSLocalCatalogEligibilityServiceProtocol {
    private let siteID: Int64
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol
    private let catalogSizeLimit: Int
    private let isFeatureFlagEnabled: Bool

    // Current eligibility state
    public private(set) var eligibilityState: POSLocalCatalogEligibilityState

    /// Initialize eligibility service and perform initial eligibility check
    public init(
        siteID: Int64,
        catalogSizeChecker: POSCatalogSizeCheckerProtocol,
        isFeatureFlagEnabled: Bool,
        catalogSizeLimit: Int? = nil
    ) async {
        self.siteID = siteID
        self.catalogSizeChecker = catalogSizeChecker
        self.isFeatureFlagEnabled = isFeatureFlagEnabled
        self.catalogSizeLimit = catalogSizeLimit ?? Constants.defaultCatalogSizeLimit

        // Perform initial check
        self.eligibilityState = .eligible // Temporary
        _ = await self.refreshEligibilityState()
    }

    public func refreshEligibilityState() async -> POSLocalCatalogEligibilityState {
        // Check feature flag first - if disabled, no need to check catalog size
        guard isFeatureFlagEnabled else {
            eligibilityState = .ineligible(reason: .featureFlagDisabled)
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
}

// MARK: - Constants

private extension POSLocalCatalogEligibilityService {
    enum Constants {
        static let defaultCatalogSizeLimit = 1000
    }
}
