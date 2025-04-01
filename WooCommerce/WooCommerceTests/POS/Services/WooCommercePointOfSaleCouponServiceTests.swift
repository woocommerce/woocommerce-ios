import XCTest
import WooFoundation
@testable import WooCommerce
@testable import Yosemite

final class WooCommercePointOfSaleCouponServiceTests: XCTestCase {
    private let siteID: Int64 = 123
    private var currencySettings: CurrencySettings!
    private var stores: MockStoresManager!
    private var storage: MockStorageManager!
    
    private var couponProvider: PointOfSaleCouponServiceProtocol!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
        storage = MockStorageManager()
        couponProvider = WooCommercePointOfSaleCouponService(siteID: siteID,
                                                             storage: storage,
                                                             currencySettings: currencySettings,
                                                             stores: stores)
        
        
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
}
