import XCTest
@testable import WooCommerce
import struct Yosemite.OrderAttributionInfo

final class OrderAttributionInfo_OriginTests: XCTestCase {
    func test_origin_when_source_type_is_utm() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "utm", source: "example.com")

        // Then
        XCTAssertEqual(sut.origin, String.localizedStringWithFormat(OrderAttributionInfo.Localization.source, "example.com"))
    }

    func test_origin_when_source_type_is_utm_and_source_nil() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "utm", source: nil)

        // Then
        XCTAssertEqual(sut.origin, String.localizedStringWithFormat(OrderAttributionInfo.Localization.source, OrderAttributionInfo.Localization.unknown))
    }

    func test_origin_when_source_type_is_organic() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "organic", source: "example.com")

        // Then
        XCTAssertEqual(sut.origin, String.localizedStringWithFormat(OrderAttributionInfo.Localization.organic, "example.com"))
    }

    func test_origin_when_source_type_is_organic_and_source_nil() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "organic", source: nil)

        // Then
        XCTAssertEqual(sut.origin, String.localizedStringWithFormat(OrderAttributionInfo.Localization.organic, OrderAttributionInfo.Localization.unknown))
    }

    func test_origin_when_source_type_is_referral() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "referral", source: "example.com")

        // Then
        XCTAssertEqual(sut.origin, String.localizedStringWithFormat(OrderAttributionInfo.Localization.referral, "example.com"))
    }

    func test_origin_when_source_type_is_referral_and_source_nil() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "referral", source: nil)

        // Then
        XCTAssertEqual(sut.origin, String.localizedStringWithFormat(OrderAttributionInfo.Localization.referral, OrderAttributionInfo.Localization.unknown))
    }

    func test_origin_when_source_type_is_typein() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "typein", source: "example.com")

        // Then
        XCTAssertEqual(sut.origin, OrderAttributionInfo.Localization.direct)
    }

    func test_origin_when_source_type_is_admin() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "admin", source: "example.com")

        // Then
        XCTAssertEqual(sut.origin, OrderAttributionInfo.Localization.webAdmin)
    }

    func test_origin_when_source_type_is_mobile_app() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "mobile_app", source: "example.com")

        // Then
        XCTAssertEqual(sut.origin, OrderAttributionInfo.Localization.mobileApp)
    }

    func test_origin_when_source_type_is_empty() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "", source: "example.com")

        // Then
        XCTAssertEqual(sut.origin, OrderAttributionInfo.Localization.unknown)
    }

    func test_origin_when_source_type_is_unknown() {
        // Given
        let sut = OrderAttributionInfo.fake().copy(sourceType: "Random unknown source type", source: "example.com")

        // Then
        XCTAssertEqual(sut.origin, OrderAttributionInfo.Localization.unknown)
    }
}
