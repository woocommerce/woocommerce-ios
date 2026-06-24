import Testing
import Foundation
@testable import Yosemite
import Hardware

struct ReceiptTextRendererTests {
    private let builder: ReceiptTextRenderer

    init() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        builder = ReceiptTextRenderer(dateFormatter: formatter)
    }

    @Test func test_makeReceiptText_when_card_details_present_then_renders_store_items_totals_and_card_block() {
        // Given
        let content = makeContent(orderNote: "Thanks for shopping!")
        let storeInformation = makeStoreInformation()
        let cardDetails = makeCardDetails(receipt: makeReceiptDetails())

        // When
        let receipt = builder.makeReceiptText(content: content, storeInformation: storeInformation, cardDetails: cardDetails)

        // Then
        // Store header + contact
        #expect(receipt.contains("My Store"))
        #expect(receipt.contains("123 Main St"))
        #expect(receipt.contains("555-1234"))
        #expect(receipt.contains("shop@example.com"))
        // Date + order number
        #expect(receipt.contains("Date Paid"))
        #expect(receipt.contains("2023-11-14"))
        #expect(receipt.contains("Order #42"))
        // Line item + total
        #expect(receipt.contains("T-Shirt"))
        #expect(receipt.contains("$25.00"))
        #expect(receipt.contains("Total"))
        #expect(receipt.contains("$27.50"))
        // Order note
        #expect(receipt.contains("Notes"))
        #expect(receipt.contains("Thanks for shopping!"))
        // Card + EMV block
        #expect(receipt.contains("Payment Method"))
        #expect(receipt.contains("Visa - 4242"))
        #expect(receipt.contains("Application Name: Visa Credit"))
        #expect(receipt.contains("AID: A0000000031010"))
        #expect(receipt.contains("Account Type: Credit"))
        // Footer
        #expect(receipt.contains("Returns accepted within 30 days"))
    }

    @Test func test_makeReceiptText_when_card_details_absent_then_renders_without_card_fields() {
        // Given
        let content = makeContent(orderNote: nil)
        let storeInformation = makeStoreInformation()

        // When
        let receipt = builder.makeReceiptText(content: content, storeInformation: storeInformation, cardDetails: nil)

        // Then
        // Common content still renders (order number is payment-method independent).
        #expect(receipt.contains("My Store"))
        #expect(receipt.contains("T-Shirt"))
        #expect(receipt.contains("Total"))
        #expect(receipt.contains("Order #42"))
        // No card / EMV block, and no dangling separators or empty values.
        #expect(receipt.contains("Payment Method") == false)
        #expect(receipt.contains("Application Name") == false)
        #expect(receipt.contains("AID:") == false)
        #expect(receipt.contains("Account Type") == false)
        #expect(receipt.contains("Visa") == false)
        #expect(receipt.contains(" - ") == false)
    }

    @Test func test_makeReceiptText_when_card_present_without_emv_then_renders_payment_method_only() {
        // Given
        let content = makeContent(orderNote: nil)
        let storeInformation = makeStoreInformation()
        let cardDetails = makeCardDetails(receipt: nil)

        // When
        let receipt = builder.makeReceiptText(content: content, storeInformation: storeInformation, cardDetails: cardDetails)

        // Then
        #expect(receipt.contains("Payment Method"))
        #expect(receipt.contains("Visa - 4242"))
        #expect(receipt.contains("Application Name") == false)
        #expect(receipt.contains("AID:") == false)
        #expect(receipt.contains("Account Type") == false)
    }

    @Test func test_makeReceiptText_when_content_is_long_then_every_line_stays_within_lineWidth() {
        // Given
        let content = makeContent(
            orderNote: "Please leave the package at the back door near the blue recycling bins, thanks so much for the help",
            lineItems: [
                ReceiptLineItem(title: "Hand-Thrown Stoneware Dinner Plate Set of Six",
                                quantity: "2",
                                amount: "$249.00",
                                attributes: [ReceiptLineAttribute(name: "Color", value: "Midnight Blue"),
                                             ReceiptLineAttribute(name: "Finish", value: "Matte Glaze")])
            ])
        let storeInformation = makeStoreInformation()
        let cardDetails = makeCardDetails(receipt: makeReceiptDetails())

        // When
        let receipt = builder.makeReceiptText(content: content, storeInformation: storeInformation, cardDetails: cardDetails)

        // Then
        for line in receipt.split(separator: "\n", omittingEmptySubsequences: false) {
            #expect(line.count <= ReceiptTextRenderer.Constants.defaultLineWidth)
        }
    }

    @Test func test_makeReceiptText_when_item_too_wide_then_wraps_title_and_keeps_amount_column() {
        // Given
        let content = makeContent(lineItems: [
            ReceiptLineItem(title: "Extra Large Premium Organic Cotton Hooded Sweatshirt",
                            quantity: "1",
                            amount: "$89.00",
                            attributes: [])
        ])

        // When
        let receipt = builder.makeReceiptText(content: content, storeInformation: makeStoreInformation(), cardDetails: nil)

        // Then
        let lines = receipt.split(separator: "\n").map(String.init)
        #expect(receipt.contains("Extra Large Premium Organic Cotton"))
        #expect(lines.contains { $0.hasSuffix("$89.00") && $0.count <= ReceiptTextRenderer.Constants.defaultLineWidth })
    }

    @Test func test_makeReceiptText_renders_line_item_attributes_after_title() {
        // Given
        let content = makeContent(lineItems: [
            ReceiptLineItem(title: "T-Shirt",
                            quantity: "2",
                            amount: "$50.00",
                            attributes: [ReceiptLineAttribute(name: "Color", value: "Blue"),
                                         ReceiptLineAttribute(name: "Size", value: "M")])
        ])

        // When
        let receipt = builder.makeReceiptText(content: content, storeInformation: makeStoreInformation(), cardDetails: nil)

        // Then
        #expect(receipt.contains("T-Shirt. Color Blue, Size M x2"))
    }

    @Test(arguments: zip(
        [CardBrand.visa, .amex, .masterCard, .discover, .jcb, .dinersClub,
         .interac, .unionPay, .eftposAu, .cartesBancaires, .girocard],
        ["Visa", "American Express", "Mastercard", "Discover", "JCB", "Diners Club",
         "Interac", "UnionPay", "eftpos", "Cartes Bancaires", "girocard"]))
    func test_makeReceiptText_renders_canonical_card_brand_name(brand: CardBrand, expectedName: String) {
        // Given
        let cardDetails = makeCardDetails(brand: brand, receipt: nil)

        // When
        let receipt = builder.makeReceiptText(content: makeContent(), storeInformation: makeStoreInformation(), cardDetails: cardDetails)

        // Then
        #expect(receipt.contains("\(expectedName) - 4242"))
    }

    @Test func test_makeReceiptText_when_brand_is_unknown_then_shows_last4_without_separator() {
        // Given
        let cardDetails = makeCardDetails(brand: .unknown, receipt: nil)

        // When
        let receipt = builder.makeReceiptText(content: makeContent(), storeInformation: makeStoreInformation(), cardDetails: cardDetails)

        // Then
        #expect(receipt.contains("Payment Method"))
        #expect(receipt.contains("4242"))
        #expect(receipt.contains(" - 4242") == false)
    }

    @Test func test_makeReceiptText_when_no_line_items_or_totals_then_still_renders_header() {
        // Given
        let content = makeContent(lineItems: [], cartTotals: [])

        // When
        let receipt = builder.makeReceiptText(content: content, storeInformation: makeStoreInformation(), cardDetails: nil)

        // Then
        #expect(receipt.contains("My Store"))
        #expect(receipt.isEmpty == false)
    }

    @Test func test_makeReceiptText_when_sections_are_empty_then_no_consecutive_separators() {
        // Given
        let content = makeContent(orderNote: nil, lineItems: [], cartTotals: [])

        // When
        let receipt = builder.makeReceiptText(content: content, storeInformation: makeStoreInformation(), cardDetails: nil)

        // Then
        let separator = String(repeating: "-", count: ReceiptTextRenderer.Constants.defaultLineWidth)
        #expect(receipt.contains(separator + "\n" + separator) == false)
    }

    @Test func test_makeReceiptText_when_emv_fields_are_long_then_every_line_stays_within_lineWidth() {
        // Given
        let longReceipt = ReceiptDetails(
            applicationPreferredName: "Some Extremely Long Card Scheme Application Preferred Name For Testing",
            dedicatedFileName: String(repeating: "A0000000031010", count: 4),
            authorizationResponseCode: "00",
            applicationCryptogram: "0102030405060708",
            terminalVerificationResults: "0000000000",
            transactionStatusInformation: "E800",
            accountType: "A Very Long Account Type Description That Should Wrap Across Several Lines")
        let cardDetails = makeCardDetails(receipt: longReceipt)

        // When
        let receipt = builder.makeReceiptText(content: makeContent(), storeInformation: makeStoreInformation(), cardDetails: cardDetails)

        // Then
        for line in receipt.split(separator: "\n", omittingEmptySubsequences: false) {
            #expect(line.count <= ReceiptTextRenderer.Constants.defaultLineWidth)
        }
    }

    @Test func test_makeReceiptText_when_amount_exceeds_lineWidth_then_every_line_stays_within_lineWidth() {
        // Given
        let hugeAmount = String(repeating: "9", count: 60)
        let content = makeContent(lineItems: [ReceiptLineItem(title: "Item", quantity: "1", amount: hugeAmount, attributes: [])],
                                  cartTotals: [ReceiptTotalLine(description: "Total", amount: hugeAmount)])

        // When
        let receipt = builder.makeReceiptText(content: content, storeInformation: makeStoreInformation(), cardDetails: nil)

        // Then
        for line in receipt.split(separator: "\n", omittingEmptySubsequences: false) {
            #expect(line.count <= ReceiptTextRenderer.Constants.defaultLineWidth)
        }
    }
}

private extension ReceiptTextRendererTests {
    func makeContent(orderNote: String? = nil,
                     lineItems: [ReceiptLineItem] = [ReceiptLineItem(title: "T-Shirt", quantity: "1", amount: "$25.00", attributes: [])],
                     cartTotals: [ReceiptTotalLine] = [ReceiptTotalLine(description: "Subtotal", amount: "$25.00"),
                                                       ReceiptTotalLine(description: "Total", amount: "$27.50")]) -> ReceiptContent {
        ReceiptContent(
            parameters: CardPresentReceiptParameters(amount: 2750,
                                                     formattedAmount: "$27.50",
                                                     currency: "USD",
                                                     date: Date(timeIntervalSince1970: 1_700_000_000),
                                                     storeName: "My Store",
                                                     cardDetails: makeCardDetails(receipt: nil),
                                                     orderID: 42),
            lineItems: lineItems,
            cartTotals: cartTotals,
            orderNote: orderNote
        )
    }

    func makeStoreInformation() -> ReceiptStoreInformation {
        ReceiptStoreInformation(storeName: "My Store",
                                storeAddress: "123 Main St",
                                phone: "555-1234",
                                email: "shop@example.com",
                                refundReturnsPolicy: "Returns accepted within 30 days")
    }

    func makeCardDetails(brand: CardBrand = .visa, receipt: ReceiptDetails?) -> CardPresentTransactionDetails {
        CardPresentTransactionDetails(last4: "4242",
                                      expMonth: 12,
                                      expYear: 2030,
                                      cardholderName: "Jane Doe",
                                      brand: brand,
                                      availableNetworks: nil,
                                      generatedCard: nil,
                                      receipt: receipt,
                                      emvAuthData: nil,
                                      wallet: nil,
                                      network: nil)
    }

    func makeReceiptDetails() -> ReceiptDetails {
        ReceiptDetails(applicationPreferredName: "Visa Credit",
                       dedicatedFileName: "A0000000031010",
                       authorizationResponseCode: "00",
                       applicationCryptogram: "0102030405060708",
                       terminalVerificationResults: "0000000000",
                       transactionStatusInformation: "E800",
                       accountType: "Credit")
    }
}
