import Foundation
import XCTest
@testable import Yosemite
import WooFoundation

class LocalIDStoreTests: XCTestCase {
    func test_local_id_store_creation() {
        let store = LocalIDStore()

        var localID = store.dispatchLocalID()
        XCTAssertEqual(localID, -1)

        localID = store.dispatchLocalID()
        XCTAssertEqual(localID, -2)
    }

    func test_is_local_id() {
        // ids <= 0 are local
        XCTAssertTrue(LocalIDStore.isIDLocal(0))
        XCTAssertTrue(LocalIDStore.isIDLocal(-1))
        XCTAssertTrue(LocalIDStore.isIDLocal(-123))
        // ids > 0 are not local
        XCTAssertFalse(LocalIDStore.isIDLocal(1))
        XCTAssertFalse(LocalIDStore.isIDLocal(123))
    }
}
