import Foundation
import Testing
import YosemiteTestHelpers
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
                         settingStoreMethods: settingStoreMethods,
                         storage: storage)
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
                _ = try await sut.provideLocalPointOfSaleCoupons(fetchStrategy: mockStrategy)
            } catch {
                let expectedError = error as? PointOfSaleCouponServiceError
                #expect(expectedError == .couponsDisabled)
            }
        }
    }

    @Test func provideLocalPointOfSaleCoupons_when_enabled_then_calls_strategy() async throws {
        // Given
        settingStoreMethods.couponsEnabled = true
        let expectedCoupons = [POSItem.coupon(
            POSCoupon(id: POSItemIdentifier(underlyingType: .product, itemID: 1), code: "test", summary: "test", dateExpires: nil)
        )]
        mockStrategy.fetchLocalCouponsResult = expectedCoupons

        // When
        let coupons = try await sut.provideLocalPointOfSaleCoupons(fetchStrategy: mockStrategy)

        // Then
        #expect(mockStrategy.fetchLocalCouponsCalled)
        #expect(coupons == expectedCoupons)
    }

    @Test func providePointOfSaleCoupons_when_enabled_then_calls_strategy() async throws {
        // Given
        settingStoreMethods.couponsEnabled = true
        let expectedCoupons = PagedItems(items: [POSItem.coupon(POSCoupon(id: POSItemIdentifier(underlyingType: .product, itemID: 1),
                                                                          code: "test",
                                                                          summary: "test",
                                                                          dateExpires: nil))],
                                         hasMorePages: false,
                                         totalItems: nil)
        mockStrategy.fetchCouponsResult = expectedCoupons

        // When
        let pagedCoupons = try await sut.providePointOfSaleCoupons(pageNumber: 1, fetchStrategy: mockStrategy)

        // Then
        #expect(mockStrategy.fetchCouponsCalled)
        #expect(mockStrategy.fetchCouponsPageNumber == 1)
        #expect(pagedCoupons.items == expectedCoupons.items)
    }

    @Test func providePointOfSaleCoupons_when_strategy_throws_and_coupons_enabled_then_throws_couponsLoadingError() async throws {
        // Given
        settingStoreMethods.couponsEnabled = true
        let error = NSError(domain: "test", code: 0)
        mockStrategy.fetchCouponsError = PointOfSaleCouponServiceError.couponsLoadingError(underlyingError: error)

        // When
        do {
            _ = try await sut.providePointOfSaleCoupons(pageNumber: 1, fetchStrategy: mockStrategy)
        } catch {
            // Then
            let expectedError = error as? PointOfSaleCouponServiceError
            #expect(expectedError == .couponsLoadingError(underlyingError: error))
        }
    }

    // MARK: - CIAB site tests

    @Test func provideLocalPointOfSaleCoupons_when_CIAB_site_then_skips_settings_check_and_returns_coupons() async throws {
        // Given
        let ciabSettingStoreMethods = MockSettingStoreMethods()
        ciabSettingStoreMethods.couponsEnabled = false
        let ciabStorage = MockStorageManager()
        let ciabMockStrategy = MockPointOfSaleCouponFetchStrategy()
        let expectedCoupons = [POSItem.coupon(
            POSCoupon(id: POSItemIdentifier(underlyingType: .product, itemID: 1), code: "test", summary: "test", dateExpires: nil)
        )]
        ciabMockStrategy.fetchLocalCouponsResult = expectedCoupons
        let ciabSut = PointOfSaleCouponService(siteID: 123,
                                               currencySettings: CurrencySettings(),
                                               settingStoreMethods: ciabSettingStoreMethods,
                                               storage: ciabStorage,
                                               isSiteCIAB: true)

        // When
        let coupons = try await ciabSut.provideLocalPointOfSaleCoupons(fetchStrategy: ciabMockStrategy)

        // Then
        #expect(coupons == expectedCoupons)
        #expect(ciabSettingStoreMethods.retrieveCouponSettingCalled == false)
    }

    @Test func providePointOfSaleCoupons_when_CIAB_site_and_fetch_fails_then_throws_loading_error_not_disabled() async throws {
        // Given
        let ciabSettingStoreMethods = MockSettingStoreMethods()
        ciabSettingStoreMethods.couponsEnabled = false
        let ciabStorage = MockStorageManager()
        let ciabMockStrategy = MockPointOfSaleCouponFetchStrategy()
        let underlyingError = NSError(domain: "test", code: 0)
        ciabMockStrategy.fetchCouponsError = PointOfSaleCouponServiceError.couponsLoadingError(underlyingError: underlyingError)
        let ciabSut = PointOfSaleCouponService(siteID: 123,
                                               currencySettings: CurrencySettings(),
                                               settingStoreMethods: ciabSettingStoreMethods,
                                               storage: ciabStorage,
                                               isSiteCIAB: true)

        // When
        do {
            _ = try await ciabSut.providePointOfSaleCoupons(pageNumber: 1, fetchStrategy: ciabMockStrategy)
        } catch {
            // Then — should be loading error, NOT couponsDisabled
            let expectedError = error as? PointOfSaleCouponServiceError
            #expect(expectedError == .couponsLoadingError(underlyingError: underlyingError))
            #expect(ciabSettingStoreMethods.retrieveCouponSettingCalled == false)
        }
    }

    @Test func providePointOfSaleCoupons_when_strategy_throws_and_coupons_disabled_then_throws_couponsDisabled() async throws {
        // Given
        settingStoreMethods.couponsEnabled = false
        let error = NSError(domain: "test", code: 0)
        mockStrategy.fetchCouponsError = PointOfSaleCouponServiceError.couponsLoadingError(underlyingError: error)

        // When
        do {
            _ = try await sut.providePointOfSaleCoupons(pageNumber: 1, fetchStrategy: mockStrategy)
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
        return fetchCouponsResult ?? .init(items: [], hasMorePages: false, totalItems: nil)
    }

    func fetchLocalCoupons() async throws -> [POSItem] {
        fetchLocalCouponsCalled = true
        if let error = fetchLocalCouponsError {
            throw error
        }
        return fetchLocalCouponsResult ?? []
    }
}
