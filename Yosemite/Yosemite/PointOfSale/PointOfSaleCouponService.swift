import protocol Networking.Network
import protocol Networking.ProductVariationsRemoteProtocol
import class Networking.ProductsRemote
import class Networking.ProductVariationsRemote
import class Networking.AlamofireNetwork
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import Storage

public final class PointOfSaleCouponService: PointOfSaleItemServiceProtocol {
    private var siteID: Int64
    private let currencyFormatter: CurrencyFormatter
    private let productsRemote: ProductsRemote
    private let variationRemote: ProductVariationsRemoteProtocol
    private let storage: StorageManagerType?

    public init(siteID: Int64,
                currencySettings: CurrencySettings,
                network: Network,
                storage: StorageManagerType? = nil) {
        self.siteID = siteID
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.productsRemote = ProductsRemote(network: network)
        self.variationRemote = ProductVariationsRemote(network: network)
        self.storage = storage
    }

    public convenience init(siteID: Int64,
                            currencySettings: CurrencySettings,
                            credentials: Credentials?,
                            storage: StorageManagerType) {
        self.init(siteID: siteID,
                  currencySettings: currencySettings,
                  network: AlamofireNetwork(credentials: credentials),
                  storage: storage)
    }

    // TODO:
    // gh-15326 - Return PagedItems<POSItem> instead.
    @MainActor
    public func providePointOfSaleCoupons() -> [POSItem] {
        guard let storage = storage else {
            return []
        }
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageCoupon.dateCreated,
                                          ascending: false)

        let resultsController = ResultsController<StorageCoupon>(storageManager: storage,
                                                                matching: predicate,
                                                                sortedBy: [descriptor])

        do {
            try resultsController.performFetch()
            let storeCoupons = resultsController.fetchedObjects
            return mapCouponsToPOSItems(coupons: storeCoupons)
        } catch {
            debugPrint(error)
            return []
        }
    }

    private func mapCouponsToPOSItems(coupons: [Coupon]) -> [POSItem] {
        coupons.compactMap { coupon in
                .coupon(POSCoupon(id: UUID(), couponID: coupon.couponID))
        }
    }

    // TODO: Remove this conformance
    public func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct, pageNumber: Int) async throws -> PagedItems<POSItem> {
        return .init(items: [], hasMorePages: false)
    }

    @MainActor
    public func providePointOfSaleItems(pageNumber: Int) async throws -> PagedItems<POSItem> {
        // Lands here when invoked from coupons controller -> Error, as won't show any in the view if we return empty.
        //return .init(items: [], hasMorePages: false)
        let coupons = providePointOfSaleCoupons()
        return .init(items: coupons, hasMorePages: false)
    }
}
