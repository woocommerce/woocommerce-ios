import XCTest
@testable import Hardware
import StripeTerminal
import Foundation
import CryptoKit

final class ReceiptRendererTest: XCTestCase {
    func test_TextWithoutHtmlSymbols() {
        let expectedResultWithoutHtmlSymbolsMd5Description = "MD5 digest: aaf7e9f13e65797745b27b35deb87d5e"
        let content = generateReceiptContent()

        let renderer = ReceiptRenderer(content: content)

        XCTAssertEqual(
            Insecure.MD5.hash(data: renderer.htmlContent().data(using: .utf8)!).description,
            expectedResultWithoutHtmlSymbolsMd5Description
        )
    }

    func test_TextWithHtmlSymbols() {
        let expectedResultWithHtmlSymbolsMd5Description = "MD5 digest: 3c24eae234431b76f371f6198858c90f"
        let stringWithHtml = "<tt><table></table></footer>"
        let content = generateReceiptContent(stringToAppend: stringWithHtml)

        let renderer = ReceiptRenderer(content: content)

        XCTAssertEqual(
            Insecure.MD5.hash(data: renderer.htmlContent().data(using: .utf8)!).description,
            expectedResultWithHtmlSymbolsMd5Description
        )
    }

    func test_TextWithVariationsSymbols() {
        let expectedResultWithHtmlSymbolsMd5Description = "MD5 digest: b28ce45f9b2be604b22ef68378529874"
        let attributeOne = ReceiptLineAttribute(name: "name_attr_1", value: "value_attr_1")
        let attributeTwo = ReceiptLineAttribute(name: "name_attr_2", value: "value_attr_2")
        let content = generateReceiptContent(attributes: [attributeOne, attributeTwo])

        let renderer = ReceiptRenderer(content: content)

        print(renderer.htmlContent())

        XCTAssertEqual(
            Insecure.MD5.hash(data: renderer.htmlContent().data(using: .utf8)!).description,
            expectedResultWithHtmlSymbolsMd5Description
        )
    }
}

private extension ReceiptRendererTest {
    func generateReceiptContent(stringToAppend: String = "", attributes: [ReceiptLineAttribute] = []) -> ReceiptContent {
        ReceiptContent(
            parameters: CardPresentReceiptParameters(
                amount: 1,
                formattedAmount: "1",
                currency: "USD",
                date: .init(timeIntervalSince1970: 1636970486),
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
                        applicationPreferredName: "Stripe Credit\(stringToAppend)",
                        dedicatedFileName: "A00000000000000\(stringToAppend)",
                        authorizationResponseCode: "0000",
                        applicationCryptogram: "XXXXXXXXXXXX",
                        terminalVerificationResults: "101010101010101010",
                        transactionStatusInformation: "6800",
                        accountType: "credit"
                    ),
                    emvAuthData: "AD*******"),
                orderID: 9201
            ),
            lineItems: [ReceiptLineItem(
                title: "Sample product #1\(stringToAppend)",
                quantity: "2",
                amount: "25",
                attributes: attributes)],
            cartTotals: [ReceiptTotalLine(description: "description", amount: "13")],
            orderNote: nil
        )
    }
}
