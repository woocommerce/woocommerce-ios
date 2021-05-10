import XCTest
@testable import Hardware
import StripeTerminal

/// Tests the mapping between CardBrand and SCPCardBrand
final class CardBrandTests: XCTestCase {
    func test_card_brand_maps_to_visa() {
        let terminalCardBrand = StripeTerminal.CardBrand.visa
        let cardBrand = CardBrand(brand: terminalCardBrand)

        XCTAssertEqual(cardBrand, .visa)
    }

    func test_card_brand_maps_to_amex() {
        let terminalCardBrand = StripeTerminal.CardBrand.amex
        let cardBrand = CardBrand(brand: terminalCardBrand)

        XCTAssertEqual(cardBrand, .amex)
    }

    func test_card_brand_maps_to_mastercard() {
        let terminalCardBrand = StripeTerminal.CardBrand.masterCard
        let cardBrand = CardBrand(brand: terminalCardBrand)

        XCTAssertEqual(cardBrand, .masterCard)
    }

    func test_card_brand_maps_to_discover() {
        let terminalCardBrand = StripeTerminal.CardBrand.discover
        let cardBrand = CardBrand(brand: terminalCardBrand)

        XCTAssertEqual(cardBrand, .discover)
    }

    func test_card_brand_maps_to_jcb() {
        let terminalCardBrand = StripeTerminal.CardBrand.JCB
        let cardBrand = CardBrand(brand: terminalCardBrand)

        XCTAssertEqual(cardBrand, .jcb)
    }

    func test_card_brand_maps_to_diners() {
        let terminalCardBrand = StripeTerminal.CardBrand.dinersClub
        let cardBrand = CardBrand(brand: terminalCardBrand)

        XCTAssertEqual(cardBrand, .dinersClub)
    }

    func test_card_brand_maps_to_unknown() {
        let terminalCardBrand = StripeTerminal.CardBrand.unknown
        let cardBrand = CardBrand(brand: terminalCardBrand)

        XCTAssertEqual(cardBrand, .unknown)
    }

    func test_card_brand_maps_others_to_unknown() throws {
        let terminalCardBrand = try XCTUnwrap(StripeTerminal.CardBrand(rawValue: 999))
        let cardBrand = CardBrand(brand: terminalCardBrand)

        XCTAssertEqual(cardBrand, .unknown)
    }

    func test_card_brand_has_icon_data_for_all_brands() throws {
        for cardBrand in Hardware.CardBrand.allCases {
            XCTAssert(cardBrand.iconData.count > 0)
        }
    }

}
