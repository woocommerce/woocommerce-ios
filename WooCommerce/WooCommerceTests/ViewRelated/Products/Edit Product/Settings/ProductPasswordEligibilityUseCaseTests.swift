import XCTest
import Yosemite
@testable import WooCommerce

final class ProductPasswordEligibilityUseCaseTests: XCTestCase {
    
    private var sut: ProductPasswordEligibilityUseCase!
    private var storageManager: MockStorageManager!
    private var stores: MockStoresManager!
    
    private let pluginName = "WooCommerce"
    
    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .testingInstance)
        sut = ProductPasswordEligibilityUseCase(stores: stores, storageManager: storageManager)
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
    }
    
    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_is_not_installed_return_false() {
        // Given
        let siteID: Int64 = 1
        stores.sessionManager.setStoreId(siteID)
        
        // When
        let result = sut.isEligibleForNewPasswordEndpoint()
        
        // Then
        XCTAssertFalse(result)
    }
    
    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_is_not_active_return_false() {
        // Given
        let inactivePlugin = SystemPlugin.fake().copy(name:pluginName, version: "9.0", active: false)
        let siteID: Int64 = 1
        stores.sessionManager.setStoreId(siteID)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: inactivePlugin)
        
        // When
        let result = sut.isEligibleForNewPasswordEndpoint()
        
        // Then
        XCTAssertFalse(result)
    }
    
    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_version_is_below_minimum_return_false() {
        // Given
        let oldVersionPlugin = SystemPlugin.fake().copy(name:pluginName, version: "7.0", active: true)
        let siteID: Int64 = 1
        stores.sessionManager.setStoreId(siteID)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: oldVersionPlugin)
        
        // When
        let result = sut.isEligibleForNewPasswordEndpoint()
        
        // Then
        XCTAssertFalse(result)
    }
    
    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_version_is_equal_or_above_minimum_return_true() {
        // Given
        let validPlugin = SystemPlugin.fake().copy(name:pluginName, version: "8.1", active: true)
        let siteID: Int64 = 1
        stores.sessionManager.setStoreId(siteID)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: validPlugin)
        
        // When
        let result = sut.isEligibleForNewPasswordEndpoint()
        
        // Then
        XCTAssertTrue(result)
    }
}
