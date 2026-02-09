import Testing
@testable import Hardware
import StripeTerminal

/// Tests the mapping between CardBrand and SCPCardBrand
struct `Card Brand Tests` {
    @Test func `card brand maps to visa`() {
        let terminalCardBrand = StripeTerminal.CardBrand.visa
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .visa)
    }

    @Test func `card brand maps to amex`() {
        let terminalCardBrand = StripeTerminal.CardBrand.amex
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .amex)
    }

    @Test func `card brand maps to mastercard`() {
        let terminalCardBrand = StripeTerminal.CardBrand.masterCard
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .masterCard)
    }

    @Test func `card brand maps to discover`() {
        let terminalCardBrand = StripeTerminal.CardBrand.discover
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .discover)
    }

    @Test func `card brand maps to jcb`() {
        let terminalCardBrand = StripeTerminal.CardBrand.JCB
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .jcb)
    }

    @Test func `card brand maps to diners`() {
        let terminalCardBrand = StripeTerminal.CardBrand.dinersClub
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .dinersClub)
    }

    @Test func `card brand maps to interac`() {
        let terminalCardBrand = StripeTerminal.CardBrand.interac
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .interac)
    }

    @Test func `card brand maps to unknown`() {
        let terminalCardBrand = StripeTerminal.CardBrand.unknown
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .unknown)
    }

    @Test func `card brand maps to cartes bancaires`() {
        let terminalCardBrand = StripeTerminal.CardBrand.cartesBancaires
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .cartesBancaires)
    }

    @Test func `card brand maps to girocard`() {
        let terminalCardBrand = StripeTerminal.CardBrand.girocard
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .girocard)
    }

    @Test func `card brand maps others to unknown`() throws {
        let terminalCardBrand: StripeTerminal.CardBrand = try #require(.init(rawValue: 999))
        let cardBrand = CardBrand(brand: terminalCardBrand)

        #expect(cardBrand == .unknown)
    }

    @Test func `card brand has icon data for all brands`() throws {
        for cardBrand in Hardware.CardBrand.allCases {
            #expect(cardBrand.iconData.count > 0)
        }
    }
}
