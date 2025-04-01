import protocol Networking.Network
import class Networking.CouponsRemote
import class Networking.AlamofireNetwork
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import Storage

public protocol PointOfSaleCouponServiceProtocol {
    func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem>
}

public final class PointOfSaleCouponService: PointOfSaleCouponServiceProtocol {
    private var siteID: Int64
    private let currencyFormatter: CurrencyFormatter
    private let couponsRemote: CouponsRemote
    private let stores: StoresManager
    private let storage: StorageManagerType

    public init(siteID: Int64,
                currencySettings: CurrencySettings,
                network: Network,
                stores: StoresManager,
                storage: StorageManagerType) {
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

    @MainActor
    public func providePointOfSaleCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
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
}

private extension PointOfSaleCouponService {
    @MainActor
    func providePointOfSaleCoupons() async -> [POSItem] {

        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageCoupon.dateCreated,
                                          ascending: false)

        let resultsController = ResultsController<StorageCoupon>(storageManager: storage,
                                                                 matching: predicate,
                                                                 sortedBy: [descriptor])

        do {
            try resultsController.performFetch()
            let storageCoupons = resultsController.fetchedObjects
            return mapCouponsToPOSItems(coupons: storageCoupons) // storageCoupons    [Yosemite.Coupon]    0 values
        } catch {
            debugPrint("Failed to load coupons from storage:", error)
            return []
        }
    }

    func mapCouponsToPOSItems(coupons: [Coupon]) -> [POSItem] {
        coupons.compactMap { coupon in
                .coupon(POSCoupon(id: UUID(), code: coupon.code))
        }
    }

    func syncCouponsFromRemote(pageNumber: Int) async {

        await withCheckedContinuation { continuation in
            let action = CouponAction.synchronizeCoupons(
                siteID: siteID,
                pageNumber: pageNumber,
                pageSize: 25,
                onCompletion: { _ in // Q: Anything to do with the result from the completion?
                    continuation.resume()
                }
            )
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}
