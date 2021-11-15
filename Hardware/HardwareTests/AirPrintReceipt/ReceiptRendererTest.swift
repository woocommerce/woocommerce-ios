import XCTest
@testable import Hardware
import StripeTerminal
import Foundation
import CryptoKit

final class ReceiptRendererTest: XCTestCase {
    func test_TextWithoutHtmlSymbols() {
        let expectedResultWithoutHtmlSymbolsMd5Description = "MD5 digest: 0a08fa3ac67c8a06fa460834ca876a7a"
        let content = generateReceiptContent()

        let renderer = ReceiptRenderer(content: content)

        XCTAssertEqual(
            Insecure.MD5.hash(data: renderer.htmlContent().data(using: .utf8)!).description,
            expectedResultWithoutHtmlSymbolsMd5Description
        )
    }

    func test_TextWithHtmlSymbols() {
        let expectedResultWithHtmlSymbolsMd5Description = "MD5 digest: d5494adfe0b653b28ed43a5444565593"
        let stringWithHtml = "<tt><table></table></footer>"
        let content = generateReceiptContent(stringToAppend: stringWithHtml)

        let renderer = ReceiptRenderer(content: content)

        XCTAssertEqual(
            Insecure.MD5.hash(data: renderer.htmlContent().data(using: .utf8)!).description,
            expectedResultWithHtmlSymbolsMd5Description
        )
    }
}

private extension ReceiptRendererTest {
    func generateReceiptContent(stringToAppend: String = "") -> ReceiptContent {
        ReceiptContent(
            parameters: CardPresentReceiptParameters(
                amount: 1,
                formattedAmount: "1",
                currency: "USD",
                date: .init(),
                storeName: "Test Store",
                cardDetails: .init(
                    last4: "1234",
                    expMonth: 12,
                    expYear: 26,
                    cardholderName: "John Smith",
                    brand: .masterCard,
                    fingerprint: "fpr*****",
                    generatedCard: "pm_******",
                    receipt: .init(
                        applicationPreferredName: "Stripe Credit \(stringToAppend)",
                        dedicatedFileName: "A00000000000000 \(stringToAppend)",
                        authorizationResponseCode: "0000",
                        applicationCryptogram: "XXXXXXXXXXXX",
                        terminalVerificationResults: "101010101010101010",
                        transactionStatusInformation: "6800",
                        accountType: "credit"
                    ),
                    emvAuthData: "AD*******"),
                orderID: 9201
            ),
            lineItems: [ReceiptLineItem(title: "Sample product #1 \(stringToAppend)", quantity: "2", amount: "25")],
            cartTotals: [ReceiptTotalLine(description: "description", amount: "13")],
            orderNote: nil
        )
    }
}
