import Foundation
import CocoaLumberjackSwift
import Yosemite
import Experiments
import protocol PointOfSale.POSLocalCatalogEligibilityServiceProtocol
import enum PointOfSale.POSLocalCatalogEligibilityState
import enum PointOfSale.POSLocalCatalogIneligibleReason
import enum PointOfSale.POSEligibilityState
import enum PointOfSale.POSIneligibleReason

@MainActor
final class POSLocalCatalogEligibilityService: @MainActor POSLocalCatalogEligibilityServiceProtocol {
    private let siteID: Int64
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol
    private let catalogSizeLimit: Int
    private let featureFlagService: FeatureFlagService
    private let posTabEligibilityState: POSEligibilityState

    // Current eligibility state
    private(set) var eligibilityState: POSLocalCatalogEligibilityState

    /// Initialize eligibility service and perform initial eligibility check
    init(
        siteID: Int64,
        catalogSizeChecker: POSCatalogSizeCheckerProtocol,
        featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
        posTabEligibilityState: POSEligibilityState,
        catalogSizeLimit: Int? = nil
    ) async {
        self.siteID = siteID
        self.catalogSizeChecker = catalogSizeChecker
        self.featureFlagService = featureFlagService
        self.posTabEligibilityState = posTabEligibilityState
        self.catalogSizeLimit = catalogSizeLimit ?? Constants.defaultCatalogSizeLimit

        // Perform initial check
        self.eligibilityState = .eligible // Temporary
        _ = await self.refreshEligibilityState()
    }

    @discardableResult func refreshEligibilityState() async -> POSLocalCatalogEligibilityState {
        // Check POS tab eligibility FIRST - no point in checking catalog if POS tab isn't eligible
        if case .ineligible = posTabEligibilityState {
            eligibilityState = .ineligible(reason: .posTabNotEligible)
            DDLogInfo("📋 POSLocalCatalogEligibilityService: POS tab not eligible for site \(siteID)")
            return eligibilityState
        }

        // Check feature flag - if disabled, no need to check catalog size
        let isFeatureFlagEnabled = featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1)
        guard isFeatureFlagEnabled else {
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
}

// MARK: - Constants

private extension POSLocalCatalogEligibilityService {
    enum Constants {
        static let defaultCatalogSizeLimit = 1000
    }
}
