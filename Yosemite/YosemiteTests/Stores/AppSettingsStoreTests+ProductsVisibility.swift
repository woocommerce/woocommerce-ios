import XCTest

@testable import Yosemite
@testable import Storage

final class AppSettingsStoreTests_ProductsVisibility: XCTestCase {

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

    func testLoadingProductsVisibilityWithoutPreviousData() {
        let expectation = self.expectation(description: "Load products visibility")
        let loadAction = AppSettingsAction.loadProductsFeatureSwitch { isVisible in
            XCTAssertFalse(isVisible)
            expectation.fulfill()
        }
        subject.onAction(loadAction)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testSettingAndLoadingProductsVisibility() {
        let expectation = self.expectation(description: "Set and load products visibility")

        let isVisibleValue = true
        let setAction = AppSettingsAction.setProductsFeatureSwitch(isVisible: isVisibleValue) {
            let loadAction = AppSettingsAction.loadProductsVisibility { isVisible in
                XCTAssertEqual(isVisible, isVisibleValue)
                expectation.fulfill()
            }
            self.subject.onAction(loadAction)
        }
        subject.onAction(setAction)

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
