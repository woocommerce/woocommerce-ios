import Foundation
import Networking
import Combine

/// Protocol for checking the size of a remote POS catalog
public protocol POSCatalogSizeCheckerProtocol {
    /// Checks the size of the remote catalog for the specified site
    /// - Parameter siteID: The site ID to check catalog size for
    /// - Returns: The size information of the catalog
    /// - Throws: Network or parsing errors
    func checkCatalogSize(for siteID: Int64) async throws -> POSCatalogSize
}

/// Implementation of catalog size checker that uses the sync remote to get counts
public struct POSCatalogSizeChecker: POSCatalogSizeCheckerProtocol {
    private let syncRemote: POSCatalogSyncRemoteProtocol

    public init(syncRemote: POSCatalogSyncRemoteProtocol) {
        self.syncRemote = syncRemote
    }

    public init(credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>,
                appPasswordSupportState: AnyPublisher<Bool, Never>) {
        let syncRemote = POSCatalogSyncRemote(network: AlamofireNetwork(credentials: credentials,
                                                                        selectedSite: selectedSite,
                                                                        appPasswordSupportState: appPasswordSupportState))
        self.init(syncRemote: syncRemote)
    }

    public func checkCatalogSize(for siteID: Int64) async throws -> POSCatalogSize {
        // Make concurrent requests to get both counts
        async let productCount = syncRemote.getProductCount(siteID: siteID)
        async let variationCount = syncRemote.getProductVariationCount(siteID: siteID)

        do {
            return try await POSCatalogSize(
                productCount: productCount,
                variationCount: variationCount
            )
        } catch {
            DDLogError(
                "⚠️ Failed to check POS catalog size for site \(siteID): \(error)"
            )
            throw error
        }
    }
}

public struct POSCatalogSize: Equatable {
    /// Number of products in the catalog
    public let productCount: Int

    /// Number of product variations in the catalog
    public let variationCount: Int

    /// Total number of items (products + variations)
    public var totalCount: Int {
        productCount + variationCount
    }

    public init(productCount: Int, variationCount: Int) {
        self.productCount = productCount
        self.variationCount = variationCount
    }
}
