import XCTest

@testable import Yosemite
@testable import Storage

final class AppSettingsStoreTests_EditProducts: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup File Storage: Load data in memory
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Test subject
    ///
    private var subject: AppSettingsStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        fileStorage = MockInMemoryStorage()
        subject = AppSettingsStore(dispatcher: dispatcher!, storageManager: storageManager!, fileStorage: fileStorage!)
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        subject = nil
        super.tearDown()
    }

    func testLoadingEditProductsWithoutPreviousData() {
        let expectation = self.expectation(description: "Load edit products")
        let loadAction = AppSettingsAction.loadEditProducts { isEnabled in
            XCTAssertTrue(isEnabled)
            expectation.fulfill()
        }
        subject.onAction(loadAction)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testSettingAndLoadingEditProducts() {
        let expectation = self.expectation(description: "Set and load edit products")

        let isEnabledValue = false
        let setAction = AppSettingsAction.setEditProducts(isEnabled: isEnabledValue) {
            let loadAction = AppSettingsAction.loadProductsVisibility { isEnabled in
                XCTAssertEqual(isEnabled, isEnabledValue)
                expectation.fulfill()
            }
            self.subject.onAction(loadAction)
        }
        subject.onAction(setAction)

        waitForExpectations(timeout: 0.1, handler: nil)
    }

}
