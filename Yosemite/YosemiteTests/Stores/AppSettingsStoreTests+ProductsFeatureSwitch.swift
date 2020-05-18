import XCTest

@testable import Yosemite
@testable import Storage

final class AppSettingsStoreTests_ProductsFeatureSwitch: XCTestCase {

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

    func testLoadingProductsFeatureSwitchWithoutPreviousData() {
        let expectation = self.expectation(description: "Load products feature switch")
        let loadAction = AppSettingsAction.loadProductsFeatureSwitch { isEnabled in
            XCTAssertFalse(isEnabled)
            expectation.fulfill()
        }
        subject.onAction(loadAction)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testSettingAndLoadingProductsFeatureSwitch() {
        let expectation = self.expectation(description: "Set and load products feature switch")

        let isEnabledValue = true
        let setAction = AppSettingsAction.setProductsFeatureSwitch(isEnabled: isEnabledValue) {
            let loadAction = AppSettingsAction.loadProductsFeatureSwitch() { isEnabled in
                XCTAssertEqual(isEnabled, isEnabledValue)
                expectation.fulfill()
            }
            self.subject.onAction(loadAction)
        }
        subject.onAction(setAction)

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
