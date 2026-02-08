import Testing
@testable import Hardware
import StripeTerminal
import Foundation
import CryptoKit

@Suite("Receipt Renderer Tests")
struct ReceiptRendererTest {
    let locale = Locale(identifier: "en_US_POSIX")
    let timeZone = TimeZone(secondsFromGMT: 0)!

    @Test func test_TextWithoutHtmlSymbols() {
        let expectedResultWithoutHtmlSymbolsMd5Description = "MD5 digest: e5db2e3510e80f8772329ae4d270167a"
        let content = generateReceiptContent()

        let renderer = ReceiptRenderer(content: content, locale: locale, timeZone: timeZone)

        #expect(
            Insecure.MD5.hash(data: renderer.htmlContent().data(using: .utf8)!).description ==
            expectedResultWithoutHtmlSymbolsMd5Description
        )
    }

    @Test func test_TextWithHtmlSymbols() {
        let expectedResultWithHtmlSymbolsMd5Description = "MD5 digest: f4dd60d176f21a1e85204404ad2a5419"
        let stringWithHtml = "<tt><table></table></footer>"
        let content = generateReceiptContent(stringToAppend: stringWithHtml)

        let renderer = ReceiptRenderer(content: content, locale: locale, timeZone: timeZone)

        #expect(
            Insecure.MD5.hash(data: renderer.htmlContent().data(using: .utf8)!).description ==
            expectedResultWithHtmlSymbolsMd5Description
        )
    }

    @Test func test_TextWithVariationsSymbols() {
        let expectedResultWithHtmlSymbolsMd5Description = "MD5 digest: 4032bc797249639da424b956a201ef88"
        let attributeOne = ReceiptLineAttribute(name: "name_attr_1", value: "value_attr_1")
        let attributeTwo = ReceiptLineAttribute(name: "name_attr_2", value: "value_attr_2")
        let content = generateReceiptContent(attributes: [attributeOne, attributeTwo])

        let renderer = ReceiptRenderer(content: content, locale: locale, timeZone: timeZone)

        #expect(
            Insecure.MD5.hash(data: renderer.htmlContent().data(using: .utf8)!).description ==
            expectedResultWithHtmlSymbolsMd5Description
        )
    }
}

private extension ReceiptRendererTest {
    func generateReceiptContent(stringToAppend: String = "", attributes: [ReceiptLineAttribute] = []) -> ReceiptContent {
        ReceiptContent(
            parameters: CardPresentReceiptParameters(
                amount: 1,
                formattedAmount: "$1",
                currency: "USD",
                date: .init(timeIntervalSince1970: 1636970486),
                storeName: "Test Store",
                cardDetails: .init(
                    last4: "1234",
                    expMonth: 12,
                    expYear: 26,
                    cardholderName: "John Smith",
                    brand: .masterCard,
                    generatedCard: "pm_******",
                    receipt: .init(
                        applicationPreferredName: "Stripe Credit\(stringToAppend)",
                        dedicatedFileName: "A00000000000000\(stringToAppend)",
                        authorizationResponseCode: "0000",
                        applicationCryptogram: "XXXXXXXXXXXX",
                        terminalVerificationResults: "101010101010101010",
                        transactionStatusInformation: "6800",
                        accountType: "credit"
                    ),
                    emvAuthData: "AD*******",
                    wallet: nil,
                    network: nil),
                orderID: 9201
            ),
            lineItems: [ReceiptLineItem(
                title: "Sample product #1\(stringToAppend)",
                quantity: "2",
                amount: "$25",
                attributes: attributes)],
            cartTotals: [ReceiptTotalLine(description: "description", amount: "$13")],
            orderNote: nil
        )
    }
}
