import Testing
@testable import Hardware
import StripeTerminal

/// Tests the mapping between CardBrand and SCPCardBrand
@Suite("Card Brand Tests")
struct CardBrandTests {
    @Test func test_card_brand_maps_to_visa() {
        let terminalCardBrand = StripeTerminal.CardBrand.visa
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .visa)
    }

    @Test func test_card_brand_maps_to_amex() {
        let terminalCardBrand = StripeTerminal.CardBrand.amex
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .amex)
    }

    @Test func test_card_brand_maps_to_mastercard() {
        let terminalCardBrand = StripeTerminal.CardBrand.masterCard
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .masterCard)
    }

    @Test func test_card_brand_maps_to_discover() {
        let terminalCardBrand = StripeTerminal.CardBrand.discover
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .discover)
    }

    @Test func test_card_brand_maps_to_jcb() {
        let terminalCardBrand = StripeTerminal.CardBrand.JCB
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .jcb)
    }

    @Test func test_card_brand_maps_to_diners() {
        let terminalCardBrand = StripeTerminal.CardBrand.dinersClub
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .dinersClub)
    }

    @Test func test_card_brand_maps_to_interac() {
        let terminalCardBrand = StripeTerminal.CardBrand.interac
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .interac)
    }

    @Test func test_card_brand_maps_to_unknown() {
        let terminalCardBrand = StripeTerminal.CardBrand.unknown
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .unknown)
    }

    @Test func test_card_brand_maps_to_cartes_bancaires() {
        let terminalCardBrand = StripeTerminal.CardBrand.cartesBancaires
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .cartesBancaires)
    }

    @Test func test_card_brand_maps_to_girocard() {
        let terminalCardBrand = StripeTerminal.CardBrand.girocard
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .girocard)
    }

    @Test func test_card_brand_maps_others_to_unknown() throws {
        let terminalCardBrand: StripeTerminal.CardBrand = try #require(.init(rawValue: 999))
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .unknown)
    }

    @Test func test_card_brand_has_icon_data_for_all_brands() throws {
        for cardBrand in Hardware.CardBrand.allCases {
            #expect(cardBrand.iconData.count > 0)
        }
    }
}
