import XCTest

@testable import Yosemite
@testable import Storage

final class AppSettingsStoreTests_ProductsFeatureSwitch: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock File Storage: Load data in memory
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Test subject
    ///
    private var subject: AppSettingsStore!

    // Previous feature switch file URL
    private lazy var productsFeatureSwitchURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent("products-feature-switch.plist")
    }()

    // Current feature switch file URL
    private lazy var productsRelease4FeatureSwitchURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent("products-m4-feature-switch.plist")
    }()

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        fileStorage = MockInMemoryStorage()
        subject = AppSettingsStore(dispatcher: dispatcher, storageManager: storageManager, fileStorage: fileStorage)
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        subject = nil
        super.tearDown()
    }

    func test_loading_products_feature_switch_without_previous_data_returns_false() {
        // Action
        var isFeatureSwitchEnabled: Bool?
        waitForExpectation { expectation in
            let loadAction = AppSettingsAction.loadProductsFeatureSwitch { isEnabled in
                isFeatureSwitchEnabled = isEnabled
                expectation.fulfill()
            }
            subject.onAction(loadAction)
        }

        // Assert
        XCTAssertEqual(isFeatureSwitchEnabled, false)
    }

    func test_setting_and_loading_products_feature_switch_returns_the_set_value() {
        // Action
        var isFeatureSwitchEnabled: Bool?
        waitForExpectation { expectation in
            let setAction = AppSettingsAction.setProductsFeatureSwitch(isEnabled: true) {
                let loadAction = AppSettingsAction.loadProductsFeatureSwitch() { isEnabled in
                    isFeatureSwitchEnabled = isEnabled
                    expectation.fulfill()
                }
                self.subject.onAction(loadAction)
            }
            subject.onAction(setAction)
        }

        // Assert
        XCTAssertEqual(isFeatureSwitchEnabled, true)
    }

    func test_setting_previous_file_URL_to_true_and_loading_products_feature_switch_returns_false() {
        // Arrange
        try? fileStorage.write(ProductsFeatureSwitchPListWrapper(isEnabled: true), to: productsFeatureSwitchURL)

        // Action
        var isFeatureSwitchEnabled: Bool?
        waitForExpectation { expectation in
            let loadAction = AppSettingsAction.loadProductsFeatureSwitch { isEnabled in
                isFeatureSwitchEnabled = isEnabled
                expectation.fulfill()
            }
            subject.onAction(loadAction)
        }

        // Assert
        XCTAssertEqual(isFeatureSwitchEnabled, false)
    }

    func test_setting_current_file_URL_to_true_and_loading_products_feature_switch_returns_true() {
        // Arrange
        try? fileStorage.write(ProductsFeatureSwitchPListWrapper(isEnabled: true), to: productsRelease4FeatureSwitchURL)

        // Action
        var isFeatureSwitchEnabled: Bool?
        waitForExpectation { expectation in
            let loadAction = AppSettingsAction.loadProductsFeatureSwitch { isEnabled in
                isFeatureSwitchEnabled = isEnabled
                expectation.fulfill()
            }
            subject.onAction(loadAction)
        }

        // Assert
        XCTAssertEqual(isFeatureSwitchEnabled, true)
    }

    func test_resetting_feature_switches_after_setting_product_switch_to_true_results_in_products_feature_switch_off() {
        // Action
        var isFeatureSwitchEnabled: Bool?
        waitForExpectation { expectation in
            // Turns on products feature switch
            let setAction = AppSettingsAction.setProductsFeatureSwitch(isEnabled: true) {
                // Resets feature switches
                let resetAction = AppSettingsAction.resetFeatureSwitches
                self.subject.onAction(resetAction)

                // Loads products feature switch
                let loadAction = AppSettingsAction.loadProductsFeatureSwitch() { isEnabled in
                    isFeatureSwitchEnabled = isEnabled
                    expectation.fulfill()
                }
                self.subject.onAction(loadAction)
            }
            subject.onAction(setAction)
        }

        // Assert
        XCTAssertEqual(isFeatureSwitchEnabled, false)
    }
}
