import XCTest
@testable import WooCommerce
@testable import Yosemite

class WCPayCardBrand_IconsTests: XCTestCase {

    func test_visa_has_icon() {
        let sut = WCPayCardBrand.visa
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-visa")
    }

    func test_amex_has_icon() {
        let sut = WCPayCardBrand.amex
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-amex")
    }

    func test_mastercard_has_icon() {
        let sut = WCPayCardBrand.mastercard
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-mastercard")
    }

    func test_discover_has_icon() {
        let sut = WCPayCardBrand.discover
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-discover")
    }

    func test_interac_has_icon() {
        let sut = WCPayCardBrand.interac
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-interac")
    }

    func test_jcb_has_icon() {
        let sut = WCPayCardBrand.jcb
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-jcb")
    }

    func test_diners_has_icon() {
        let sut = WCPayCardBrand.diners
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-diners")
    }

    func test_unionpay_has_icon() {
        let sut = WCPayCardBrand.unionpay
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-unionpay")
    }

    func test_cartes_bancaires_has_icon() {
        let sut = WCPayCardBrand.cartesBancaires
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-cartes-bancaires")
    }

    func test_eftpos_au_has_icon() {
        let sut = WCPayCardBrand.eftposAu
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-eftpos-au")
    }

    func test_unknown_has_icon() {
        let sut = WCPayCardBrand.unknown
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.iconName, "card-brand-unknown")
    }

}
