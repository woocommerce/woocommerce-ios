import class Networking.ProductsRemote
import class Networking.AlamofireNetwork

public protocol POSProductFilterServiceProtocol {
    func fetchAllTags() async throws -> [ProductTag]
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
}

public final class POSProductFilterServicePreview: POSProductFilterServiceProtocol {
    public init() {}
    public func fetchAllTags() async throws -> [ProductTag] {
        []
    }
}
