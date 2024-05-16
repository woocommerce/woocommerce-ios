import XCTest
import Yosemite
@testable import WooCommerce

final class MostActiveCouponsCardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 134
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()

        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    @MainActor
    func test_coupons_is_updated_correctly() async {
        // Given
        let viewModel = MostActiveCouponsCardViewModel(siteID: sampleSiteID, stores: stores)
        let coupons = [Coupon.fake().copy(couponID: 1),
                       Coupon.fake().copy(couponID: 2),
                       Coupon.fake().copy(couponID: 3)]

        // When
        mockLoadCouponsCardSuccess(actionCouponReports: [.fake()], coupons: coupons)
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.coupons, coupons)
    }

    @MainActor
    func test_syncingData_is_updated_correctly() async {
        // Given
        let viewModel = MostActiveCouponsCardViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertFalse(viewModel.syncingData)

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .loadMostActiveCoupons(_, _, _, completion):
                XCTAssertTrue(viewModel.syncingData)
                completion(.success([CouponReport.fake()]))
            case let .loadCoupons(_, _, completion):
                XCTAssertTrue(viewModel.syncingData)
                completion(.success([Coupon.fake()]))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertFalse(viewModel.syncingData)
    }

    @MainActor
    func test_syncingError_is_updated_correctly_when_loading_most_active_coupons_fails() async {
        // Given
        let viewModel = MostActiveCouponsCardViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertNil(viewModel.syncingError)
        let error = NSError(domain: "test", code: 500)

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .loadMostActiveCoupons(_, _, _, completion):
                completion(.failure(error))
            case let .loadCoupons(_, _, completion):
                XCTAssertTrue(viewModel.syncingData)
                completion(.success([Coupon.fake()]))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, error)
    }

    @MainActor
    func test_syncingError_is_updated_correctly_when_loading_coupons_fails() async {
        // Given
        let viewModel = MostActiveCouponsCardViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertNil(viewModel.syncingError)
        let error = NSError(domain: "test", code: 500)

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .loadMostActiveCoupons(_, _, _, completion):
                completion(.success([CouponReport.fake()]))
            case let .loadCoupons(_, _, completion):
                completion(.failure(error))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, error)
    }
}

private extension MostActiveCouponsCardViewModelTests {
    func mockLoadCouponsCardSuccess(actionCouponReports: [CouponReport],
                                    coupons: [Coupon]) {
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .loadMostActiveCoupons(_, _, _, completion):
                completion(.success(actionCouponReports))
            case let .loadCoupons(_, _, completion):
                completion(.success(coupons))
            default:
                break
            }
        }
    }
}
