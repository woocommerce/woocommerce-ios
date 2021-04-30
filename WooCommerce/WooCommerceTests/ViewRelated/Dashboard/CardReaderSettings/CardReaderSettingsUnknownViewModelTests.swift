import XCTest
@testable import Yosemite
@testable import WooCommerce

import Storage

final class CardReaderSettingsUnknownViewModelTests: XCTestCase {
    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_did_change_should_show_returns_true_if_no_known_no_connected_readers() throws {
        let expectation = self.expectation(description: "Check shouldShow returns isTrue")
        let _ = CardReaderSettingsUnknownViewModel(didChangeShouldShow: { shouldShow in
            XCTAssertTrue(shouldShow == .isTrue)
            expectation.fulfill()
        } )

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
