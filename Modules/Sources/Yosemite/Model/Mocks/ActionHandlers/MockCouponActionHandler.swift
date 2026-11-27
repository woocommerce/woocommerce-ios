import Foundation
import Storage
import Networking

struct MockCouponActionHandler: MockActionHandler {

    typealias ActionType = CouponAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    private var storage: StorageType! {
        storageManager.viewStorage
    }

    init(objectGraph: MockObjectGraph, storageManager: StorageManagerType) {
        self.objectGraph = objectGraph
        self.storageManager = storageManager
    }

    func handle(action: ActionType) {
        // The dashboard dispatches these coupon actions through MockStoresManager on the main thread.
        switch action {
        case .loadMostActiveCoupons(_, _, _, _, let onCompletion):
            let reports = objectGraph.couponReports
            MainActor.assumeIsolated { onCompletion(.success(reports)) }
        case .loadCoupons(_, _, let onCompletion):
            let coupons = objectGraph.coupons
            save(mocks: coupons, as: StorageCoupon.self) { _ in }
            MainActor.assumeIsolated { onCompletion(.success(coupons)) }
        default:
            unimplementedAction(action: action)
        }
    }
}
