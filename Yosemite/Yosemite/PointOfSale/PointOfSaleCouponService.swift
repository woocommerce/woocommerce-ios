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
    private let storage: StorageManagerType?
    private let couponService: CouponServiceProtocol

    init(siteID: Int64,
         currencySettings: CurrencySettings,
         couponService: CouponServiceProtocol,
         storage: StorageManagerType) {
        self.siteID = siteID
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.storage = storage
        self.couponService = couponService
    }

    public convenience init(siteID: Int64,
                            currencySettings: CurrencySettings,
                            credentials: Credentials?,
                            storage: StorageManagerType) {
        let network = AlamofireNetwork(credentials: credentials)
        self.init(siteID: siteID,
                  currencySettings: currencySettings,
                  couponService: CouponService(storageManager: storage, network: network),
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

    func mapCouponsToPOSItems(coupons: [Coupon]) -> [POSItem] {
        coupons.compactMap { coupon in
                .coupon(POSCoupon(id: UUID(), code: coupon.code))
        }
    }

    func syncCouponsFromRemote(pageNumber: Int) async {
        await withCheckedContinuation { continuation in
            couponService.synchronizeCoupons(
                siteID: siteID,
                pageNumber: pageNumber,
                pageSize: 25,
                onCompletion: { _ in
                    continuation.resume()
                }
            )
        }
    }
}
