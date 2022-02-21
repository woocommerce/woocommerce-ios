import XCTest
@testable import WooCommerce
@testable import Yosemite

class WCPayCardBrand_IconsTests: XCTestCase {

    func test_visa_has_icon_and_card_shaped_aspect_ratio() {
        let sut = WCPayCardBrand.visa
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-visa")
        XCTAssertEqual(sut.iconAspectHorizontal, 1.58)
    }

    func test_amex_has_icon_and_card_shaped_aspect_ratio() {
        let sut = WCPayCardBrand.amex
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-amex")
        XCTAssertEqual(sut.iconAspectHorizontal, 1.58)
    }

    func test_mastercard_has_icon_and_card_shaped_aspect_ratio() {
        let sut = WCPayCardBrand.mastercard
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-mastercard")
        XCTAssertEqual(sut.iconAspectHorizontal, 1.58)
    }

    func test_discover_has_icon_and_card_shaped_aspect_ratio() {
        let sut = WCPayCardBrand.discover
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-discover")
        XCTAssertEqual(sut.iconAspectHorizontal, 1.58)
    }

    func test_interac_has_icon_and_square_aspect_ratio() {
        let sut = WCPayCardBrand.interac
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-interac")
        XCTAssertEqual(sut.iconAspectHorizontal, 1)
    }

    func test_jcb_has_icon_and_card_shaped_aspect_ratio() {
        let sut = WCPayCardBrand.jcb
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-jcb")
        XCTAssertEqual(sut.iconAspectHorizontal, 1.58)
    }

    func test_diners_has_icon_and_card_shaped_aspect_ratio() {
        let sut = WCPayCardBrand.diners
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-diners")
        XCTAssertEqual(sut.iconAspectHorizontal, 1.58)
    }

    func test_unionpay_has_icon_and_card_shaped_aspect_ratio() {
        let sut = WCPayCardBrand.unionpay
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-unionpay")
        XCTAssertEqual(sut.iconAspectHorizontal, 1.58)
    }

    func test_unknown_has_icon_and_card_shaped_aspect_ratio() {
        let sut = WCPayCardBrand.unknown
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-unknown")
        XCTAssertEqual(sut.iconAspectHorizontal, 1.58)
    }

}
