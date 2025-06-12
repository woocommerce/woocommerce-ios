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
        try await Task.sleep(nanoseconds: 500_000_000) // simulates network delay

        let fakeTag1 = ProductTag(siteID: 0,
                                  tagID: 123,
                                  name: "chairs",
                                  slug: "chairs")
        let fakeTag2 = ProductTag(siteID: 0,
                                  tagID: 124,
                                  name: "Some tables",
                                  slug: "some-tables")
        return [fakeTag1, fakeTag2]
    }
}

public final class POSProductFilterServicePreview: POSProductFilterServiceProtocol {
    public init() {}
    public func fetchAllTags() async throws -> [ProductTag] {
        []
    }
}
