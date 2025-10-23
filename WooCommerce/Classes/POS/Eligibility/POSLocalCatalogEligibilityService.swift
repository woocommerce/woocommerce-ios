import Foundation
import CocoaLumberjackSwift
import Yosemite
import Experiments
import protocol PointOfSale.POSLocalCatalogEligibilityServiceProtocol
import enum PointOfSale.POSLocalCatalogEligibilityState
import enum PointOfSale.POSLocalCatalogIneligibleReason

@MainActor
final class POSLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    private let siteID: Int64
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol
    private let catalogSizeLimit: Int
    private let featureFlagService: FeatureFlagService

    // Current eligibility state
    private(set) var eligibilityState: POSLocalCatalogEligibilityState

    /// Initialize eligibility service and perform initial eligibility check
    init(
        siteID: Int64,
        catalogSizeChecker: POSCatalogSizeCheckerProtocol,
        featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
        catalogSizeLimit: Int? = nil
    ) async {
        self.siteID = siteID
        self.catalogSizeChecker = catalogSizeChecker
        self.featureFlagService = featureFlagService
        self.catalogSizeLimit = catalogSizeLimit ?? Constants.defaultCatalogSizeLimit

        // Perform initial check
        self.eligibilityState = .eligible // Temporary
        _ = await self.refreshEligibilityState()
    }

    func refreshEligibilityState() async -> POSLocalCatalogEligibilityState {
        // Check feature flag first - if disabled, no need to check catalog size
        let isFeatureFlagEnabled = featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1)
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
