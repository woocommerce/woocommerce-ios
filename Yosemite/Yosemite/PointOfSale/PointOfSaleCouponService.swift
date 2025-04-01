import protocol Networking.Network
import protocol Networking.ProductVariationsRemoteProtocol
import class Networking.CouponsRemote
import class Networking.AlamofireNetwork
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import Storage

public final class PointOfSaleCouponService: PointOfSaleItemServiceProtocol {
    private var siteID: Int64
    private let currencyFormatter: CurrencyFormatter
    private let couponsRemote: CouponsRemote
    private let stores: StoresManager?
    private let storage: StorageManagerType?

    public init(siteID: Int64,
                currencySettings: CurrencySettings,
                network: Network,
                stores: StoresManager? = nil,
                storage: StorageManagerType? = nil) {
        self.siteID = siteID
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.couponsRemote = CouponsRemote(network: network)
        self.stores = stores
        self.storage = storage
    }

    public convenience init(siteID: Int64,
                            currencySettings: CurrencySettings,
                            credentials: Credentials?,
                            stores: StoresManager,
                            storage: StorageManagerType) {
        self.init(siteID: siteID,
                  currencySettings: currencySettings,
                  network: AlamofireNetwork(credentials: credentials),
                  stores: stores,
                  storage: storage)
    }

    // TODO:
    // gh-15326 - Return PagedItems<POSItem> instead.
    @MainActor
    public func providePointOfSaleCoupons() async -> [POSItem] {
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
            let storageCoupons = resultsController.fetchedObjects
            return mapCouponsToPOSItems(coupons: storageCoupons)
        } catch {
            debugPrint("Failed to load coupons from storage:", error)
            return []
        }
    }

    private func mapCouponsToPOSItems(coupons: [Coupon]) -> [POSItem] {
        coupons.compactMap { coupon in
                .coupon(POSCoupon(id: UUID(), code: coupon.code))
        }
    }

    // TODO: Remove this conformance
    public func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct, pageNumber: Int) async throws -> PagedItems<POSItem> {
        return .init(items: [], hasMorePages: false)
    }

    @MainActor
    public func providePointOfSaleItems(pageNumber: Int) async throws -> PagedItems<POSItem> {
        let coupons = await providePointOfSaleCoupons()

        if !coupons.isEmpty {
            // Fire-and-forget sync
            Task.detached {
                await self.syncCouponsFromRemote(pageNumber: pageNumber)
            }
            return .init(items: coupons, hasMorePages: false)
        } else {
            // Wait for the sync to complete
            await syncCouponsFromRemote(pageNumber: pageNumber)
            let refreshedCoupons = await providePointOfSaleCoupons()
            return .init(items: refreshedCoupons, hasMorePages: false)
        }
    }

    private func syncCouponsFromRemote(pageNumber: Int) async {
        guard let stores = stores else {
            return
        }

        await withCheckedContinuation { continuation in
            let action = CouponAction.synchronizeCoupons(
                siteID: siteID,
                pageNumber: pageNumber,
                pageSize: 25,
                onCompletion: { _ in
                    continuation.resume()
                }
            )
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}
