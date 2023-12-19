@testable import WooCommerce
import Foundation

final class MockStoreCreationStoreSwitchScheduler: StoreCreationStoreSwitchScheduler {
    func savePendingStoreSwitch(siteID: Int64, expectedStoreName: String) {
        //no-op
    }

    func removePendingStoreSwitch() {
        //no-op
    }

    var isPendingStoreSwitchMockValue = true
    var isPendingStoreSwitchChecked = false
    var isPendingStoreSwitch: Bool {
        isPendingStoreSwitchChecked = true
        return isPendingStoreSwitchMockValue
    }

    var listenToPendingStoreAndReturnSiteIDOnceReadyCalled = false
    var siteIDMockValue: Int64 = 0
    func listenToPendingStoreAndReturnSiteIDOnceReady() async throws -> Int64? {
        listenToPendingStoreAndReturnSiteIDOnceReadyCalled = true
        return siteIDMockValue
    }
}
