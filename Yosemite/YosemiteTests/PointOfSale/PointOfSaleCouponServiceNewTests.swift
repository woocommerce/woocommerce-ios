
import Testing

@testable import Networking
@testable import Yosemite
import WooFoundation

struct PointOfSaleCouponServiceNewTests {
    
    

//    @Test func test_good() async throws {
//        let siteID: Int64 = 1
//        let currencySettings = CurrencySettings()
//        let network = MockNetwork()
//        let stores = MockStoresManager(objectGraph: <#T##any MockObjectGraph#>, storageManager: <#T##any StorageManagerType#>)
//        
//        let sut = PointOfSaleCouponService(siteID: siteID, currencySettings: currencySettings, network: network, stores: <#T##any StoresManager#>, storage: <#T##any StorageManagerType#>)
//    }

}


/**
 final class PointOfSaleCouponServiceTests: XCTestCase {
     private let siteID: Int64 = 1
     private var couponProvider: PointOfSaleCouponServiceProtocol!
     private var network: MockNetwork!
     private var currencySettings: CurrencySettings!
     private var stores: MockStoresManager!
     private var storage: MockStorageManager! // not needed? Through stores.

     override func setUp() {
         super.setUp()
         currencySettings = CurrencySettings()
         network = MockNetwork()
         storage = MockStorageManager()

         stores = MockStoresManager(objectGraph: ScreenshotObjectGraph(), storageManager: storage)

         couponProvider = PointOfSaleCouponService(siteID: siteID,
                                                   currencySettings: currencySettings,
                                                   network: network,
                                                   stores: stores,
                                                   storage: storage)
     }

     override func tearDown() {
         currencySettings = nil
         network = nil
         couponProvider = nil
         super.tearDown()
     }

     /* Whese tests will either return zero coupons or throw an error for all cases, since we cannot inject stores or storage from Yosemite, so it never passes the required guards for dependencies on PointOfSaleCouponService, eg:
      
      func providePointOfSaleCoupons() async -> [POSItem] {
          guard let storage = storage else {
              return []
          }
      
      or
      
      func syncCouponsFromRemote(pageNumber: Int) async {
          guard let stores = stores else {
              return
          }
      
      It relies on passing them from ServiceLocator, but they should never be nil.
     */
     func test_couponProvider_when_pageNumber_is_zero_then_succeeds_with_no_coupons() async {
         let expectedCoupons = 0
         do {
             let coupons = try await couponProvider.providePointOfSaleCoupons(pageNumber: 0)
             XCTAssertEqual(coupons.items.count, expectedCoupons)
         } catch {
             XCTFail("Expected success, got error")
         }
     }

     func test_some_coupons() async {
         let expectedCoupons = 3
         network.simulateResponse(requestUrlSuffix: "coupons", filename: "coupons-all")
         // When
         //let sut = PointOfSaleCouponService(siteID: siteID, currencySettings: currencySettings, credentials: nil, stores: stores, storage: stor)
         do {
             let coupons = try await couponProvider.providePointOfSaleCoupons(pageNumber: 1)
             XCTAssertEqual(coupons.items.count, expectedCoupons) // XCTAssertEqual failed: ("0") is not equal to ("3")
         } catch {
             // Then
             XCTFail("Error: \(error)")
         }
     }
 }
 */
