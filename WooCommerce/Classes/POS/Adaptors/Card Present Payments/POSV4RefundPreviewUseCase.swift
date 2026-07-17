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

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let availabilityCache: V4RefundAvailabilityCache
    private let minimumWooVersion: String

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         availabilityCache: V4RefundAvailabilityCache = .shared,
         minimumWooVersion: String = Constants.minimumWooVersion) {
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.availabilityCache = availabilityCache
        self.minimumWooVersion = minimumWooVersion
    }

    func previewRefund(siteID: Int64, orderID: Int64, lineItems: [RefundV4LineItem]) async -> Result {
        let cachedAvailability = availabilityCache.isV4Available(siteID: siteID)
        guard featureFlagService.isFeatureFlagEnabled(.posRefundsV4),
              lineItems.isNotEmpty,
              cachedAvailability != false,
              cachedAvailability == true || !isWooVersionBelowV4Support() else {
            return .fallbackToLocal
        }

        switch await dispatchPreview(siteID: siteID, orderID: orderID, lineItems: lineItems) {
        case .success(let preview):
            availabilityCache.markV4Available(siteID: siteID)
            return .serverCalculated(preview)
        case .failure(let error):
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

    private func dispatchPreview(siteID: Int64,
                                 orderID: Int64,
                                 lineItems: [RefundV4LineItem]) async -> Swift.Result<RefundPreview, Error> {
        await withCheckedContinuation { continuation in
            let action = RefundAction.previewRefund(siteID: siteID, orderID: orderID, lineItems: lineItems) { result in
                continuation.resume(returning: result)
            }
            stores.dispatch(action)
        }
    }

    private enum Constants {
        static let minimumWooVersion = "10.9.0"
    }
}
