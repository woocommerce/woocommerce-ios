import Foundation
import Yosemite
import Experiments
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError
import class WooFoundation.VersionHelpers

@MainActor
final class POSV4RefundPreviewUseCase {

    enum Result: Equatable {
        case serverCalculated(RefundPreview)
        case fallbackToLocal
        case error
    }

    private let refundService: RefundServiceProtocol
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let availabilityCache: V4RefundAvailabilityCache
    private let minimumWooVersion: String

    init(refundService: RefundServiceProtocol,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         availabilityCache: V4RefundAvailabilityCache = .shared,
         minimumWooVersion: String = Constants.minimumWooVersion) {
        self.refundService = refundService
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.availabilityCache = availabilityCache
        self.minimumWooVersion = minimumWooVersion
    }

    func previewRefund(siteID: Int64, orderID: Int64, lineItems: [RefundPreviewLineItem]) async -> Result {
        let cachedAvailability = availabilityCache.isV4Available(siteID: siteID)
        guard featureFlagService.isFeatureFlagEnabled(.posRefundsV4),
              lineItems.isNotEmpty,
              cachedAvailability != false,
              cachedAvailability == true || !isWooVersionBelowV4Support() else {
            return .fallbackToLocal
        }

        do {
            let preview = try await refundService.previewRefund(siteID: siteID, orderID: orderID, lineItems: lineItems)
            availabilityCache.markV4Available(siteID: siteID)
            return .serverCalculated(preview)
        } catch {
            if isRouteNotRegistered(error) {
                availabilityCache.markV4Unavailable(siteID: siteID)
                return .fallbackToLocal
            }
            return .error
        }
    }

    private func isWooVersionBelowV4Support() -> Bool {
        guard let version = stores.sessionManager.cachedWooCommerceVersion else {
            return false
        }
        return !VersionHelpers.isVersionSupported(version: version,
                                                  minimumRequired: minimumWooVersion,
                                                  includesDevAndBetaVersions: true)
    }

    private func isRouteNotRegistered(_ error: Error) -> Bool {
        if let dotcomError = error as? DotcomError, case .noRestRoute = dotcomError {
            return true
        }
        if let networkError = error as? NetworkError, case .notFound = networkError, networkError.errorCode == "rest_no_route" {
            return true
        }
        return false
    }

    private enum Constants {
        static let minimumWooVersion = "10.9.0"
    }
}
