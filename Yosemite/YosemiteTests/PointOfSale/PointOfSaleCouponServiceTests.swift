import Testing
@testable import Yosemite
import class WooFoundation.CurrencySettings

struct PointOfSaleCouponServiceTests {
    private let sut: PointOfSaleCouponService
    private let settingStoreMethods: MockSettingStoreMethods
    private let storage: MockStorageManager
    private let mockStrategy: MockPointOfSaleCouponFetchStrategy
    private let sampleSiteID: Int64 = 123

    init() {
        self.settingStoreMethods = MockSettingStoreMethods()
        self.storage = MockStorageManager()
        self.mockStrategy = MockPointOfSaleCouponFetchStrategy()
        self.sut = .init(siteID: sampleSiteID,
                         currencySettings: CurrencySettings(),
                         couponStoreMethods: MockCouponStoreMethods(),
                         settingStoreMethods: settingStoreMethods,
                         storage: storage,
                         strategy: mockStrategy
        )
    }

    @Test func provideLocalPointOfSaleCoupons_when_disabled_then_expects_couponsDisabled_error() async throws {
        // Given
        settingStoreMethods.couponsEnabled = false

        // When
        await confirmation(expectedCount: 1) { confirmation in
            settingStoreMethods.retrieveCouponSetting(siteID: sampleSiteID, onCompletion: { result in
                switch result {
                case let .success(isEnabled):
                    #expect(isEnabled == false)
                    confirmation()
                case .failure:
                    break
                }
            })

            do {
                // Then
                _ = try await sut.provideLocalPointOfSaleCoupons()
            } catch {
                let expectedError = error as? PointOfSaleCouponServiceError
                #expect(expectedError == .couponsDisabled)
            }
        }
    }

    @Test func provideLocalPointOfSaleCoupons_when_enabled_then_calls_strategy() async throws {
        // Given
        settingStoreMethods.couponsEnabled = true
        let expectedCoupons = [POSItem.coupon(POSCoupon(id: UUID(), code: "test", summary: "test", dateExpires: nil))]
        mockStrategy.fetchLocalCouponsResult = expectedCoupons

        // When
        let coupons = try await sut.provideLocalPointOfSaleCoupons()

        // Then
        #expect(mockStrategy.fetchLocalCouponsCalled)
        #expect(coupons == expectedCoupons)
    }

    @Test func providePointOfSaleCoupons_when_enabled_then_calls_strategy() async throws {
        // Given
        settingStoreMethods.couponsEnabled = true
        let expectedCoupons = PagedItems(items: [POSItem.coupon(POSCoupon(id: UUID(), code: "test", summary: "test", dateExpires: nil))], hasMorePages: false)
        mockStrategy.fetchCouponsResult = expectedCoupons

        // When
        let coupons = try await sut.providePointOfSaleCoupons(pageNumber: 0)

        // Then
        #expect(mockStrategy.fetchCouponsCalled)
        #expect(mockStrategy.fetchCouponsPageNumber == 0)
        #expect(coupons.items.count == expectedCoupons.items.count)
    }

    @Test func providePointOfSaleCoupons_when_strategy_throws_and_coupons_enabled_then_throws_couponsLoadingError() async throws {
        // Given
        settingStoreMethods.couponsEnabled = true
        mockStrategy.fetchCouponsError = PointOfSaleCouponServiceError.couponsLoadingError

        // When
        do {
            _ = try await sut.providePointOfSaleCoupons(pageNumber: 0)
        } catch {
            // Then
            let expectedError = error as? PointOfSaleCouponServiceError
            #expect(expectedError == .couponsLoadingError)
        }
    }

    @Test func providePointOfSaleCoupons_when_strategy_throws_and_coupons_disabled_then_throws_couponsDisabled() async throws {
        // Given
        settingStoreMethods.couponsEnabled = false
        mockStrategy.fetchCouponsError = PointOfSaleCouponServiceError.couponsLoadingError

        // When
        do {
            _ = try await sut.providePointOfSaleCoupons(pageNumber: 0)
        } catch {
            // Then
            let expectedError = error as? PointOfSaleCouponServiceError
            #expect(expectedError == .couponsDisabled)
        }
    }
}

private class MockPointOfSaleCouponFetchStrategy: PointOfSaleCouponFetchStrategy {
    var fetchCouponsCalled = false
    var fetchLocalCouponsCalled = false
    var fetchCouponsPageNumber: Int?
    var fetchCouponsResult: PagedItems<POSItem>?
    var fetchLocalCouponsResult: [POSItem]?
    var fetchCouponsError: Error?
    var fetchLocalCouponsError: Error?

    func fetchCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        fetchCouponsCalled = true
        fetchCouponsPageNumber = pageNumber
        if let error = fetchCouponsError {
            throw error
        }
        return fetchCouponsResult ?? .init(items: [], hasMorePages: false)
    }

    func fetchLocalCoupons() async throws -> [POSItem] {
        fetchLocalCouponsCalled = true
        if let error = fetchLocalCouponsError {
            throw error
        }
        return fetchLocalCouponsResult ?? []
    }
}
