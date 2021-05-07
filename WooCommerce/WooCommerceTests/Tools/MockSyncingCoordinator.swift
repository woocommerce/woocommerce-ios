import Foundation
@testable import WooCommerce

final class MockSyncingCoordinator: SyncingCoordinatorProtocol {
    var delegate: SyncingCoordinatorDelegate?

    var spyDidCallEnsureNextPageIsSynchronized = false
    var spyEnsureNextPageIsSynchronizedLastVisibleIndex: Int?

    var spyDidCallResynchronize = false
    var spyResynchronizeReason: String?

    var spyDidCallSynchronizeFirstPage = false
    var spySynchronizeFirstPageReason: String?

    func ensureNextPageIsSynchronized(lastVisibleIndex: Int) {
        spyDidCallEnsureNextPageIsSynchronized = true
        spyEnsureNextPageIsSynchronizedLastVisibleIndex = lastVisibleIndex
    }

    func resynchronize(reason: String?, onCompletion: (() -> Void)?) {
        spyDidCallResynchronize = true
        spyResynchronizeReason = reason
        onCompletion?()
    }

    func synchronizeFirstPage(reason: String?, onCompletion: (() -> Void)?) {
        spyDidCallSynchronizeFirstPage = true
        spySynchronizeFirstPageReason = reason
        onCompletion?()
    }
}
