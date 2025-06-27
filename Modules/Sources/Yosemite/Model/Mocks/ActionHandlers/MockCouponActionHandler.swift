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
        switch action {
        case .loadMostActiveCoupons(_, _, _, _, let onCompletion):
            onCompletion(.success(objectGraph.couponReports))
        case .loadCoupons(_, _, let onCompletion):
            save(mocks: objectGraph.coupons, as: StorageCoupon.self) { _ in }
            onCompletion(.success(objectGraph.coupons))
        default:
            unimplementedAction(action: action)
        }
    }
}
