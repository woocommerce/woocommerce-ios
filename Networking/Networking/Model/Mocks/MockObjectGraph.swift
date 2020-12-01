import Foundation

public protocol MockObjectGraph {
    var userCredentials: Credentials { get }
    var defaultAccount: Account { get }
    var defaultSite: Site { get }

    var sites: [Site] { get }
    var orders: [Order] { get }
    var products: [Product] { get }

    func accountWithId(id: Int64) -> Account
    func accountSettingsWithUserId(userId: Int64) -> AccountSettings

    func siteWithId(id: Int64) -> Site
}

extension MockObjectGraph {
    func products(forSiteId siteId: Int64) -> [Product] {
        return products.filter { $0.siteID == siteId }
    }

    func products(forSiteId siteId: Int64, productIds: [Int64]) -> [Product] {
        return products(forSiteId: siteId).filter { productIds.contains($0.productID) }
    }
}
