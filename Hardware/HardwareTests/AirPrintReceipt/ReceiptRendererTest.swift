import XCTest
@testable import Hardware
import StripeTerminal
import Foundation
import CryptoKit

final class ReceiptRendererTest: XCTestCase {
    func test_TextWithoutHtmlSymbols() {
        let expectedResultWithoutHtmlSymbolsMd5Description = "MD5 digest: 9065a7a64f233451e01f90ee3b09fff5"
        let content = generateReceiptContent()

        let renderer = ReceiptRenderer(content: content)

        XCTAssertEqual(
            Insecure.MD5.hash(data: renderer.htmlContent().data(using: .utf8)!).description,
            expectedResultWithoutHtmlSymbolsMd5Description
        )
    }

    func test_TextWithHtmlSymbols() {
        let expectedResultWithHtmlSymbolsMd5Description = "MD5 digest: 2c0110b48a2923c5928fdbab8fc27a43"
        let stringWithHtml = "<tt><table></table></footer>"
        let content = generateReceiptContent(stringToAppend: stringWithHtml)

        let renderer = ReceiptRenderer(content: content)

        XCTAssertEqual(
            Insecure.MD5.hash(data: renderer.htmlContent().data(using: .utf8)!).description,
            expectedResultWithHtmlSymbolsMd5Description
        )
    }

    func test_TextWithVariationsSymbols() {
        let expectedResultWithHtmlSymbolsMd5Description = "MD5 digest: 3f29686ee6c446e6a04297d1f301b8f1"
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
