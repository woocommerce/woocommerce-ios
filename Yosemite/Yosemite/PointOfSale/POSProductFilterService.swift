import class Networking.ProductsRemote
import class Networking.AlamofireNetwork

public protocol POSProductFilterServiceProtocol {
    func fetchAllTags() async throws -> [ProductTag]
    func fetchProductsByTag() async throws -> PagedItems<POSProduct>
}

public final class POSProductFilterService: POSProductFilterServiceProtocol {
    private let siteID: Int64
    private let productsRemote: ProductsRemote

    public init(siteID: Int64,
                credentials: Credentials?) {
        let network = AlamofireNetwork(credentials: credentials)

        self.siteID = siteID
        self.productsRemote = ProductsRemote(network: network)
    }

    public func fetchAllTags() async throws -> [ProductTag] {
        try await productsRemote.fetchAlltags(for: siteID)
    }

    public func fetchProductsByTag() async throws -> PagedItems<POSProduct> {
        try await productsRemote.fetchProductsByTag(for: siteID)
    }
}

public final class POSProductFilterServicePreview: POSProductFilterServiceProtocol {
    public init() {}
    public func fetchAllTags() async throws -> [ProductTag] {
        []
    }
    
    public func fetchProductsByTag() async throws -> PagedItems<POSProduct> {
        .init(items: [], hasMorePages: false, totalItems: nil)
    }
}
