import Testing
import Foundation
@testable import Hardware

struct StarReceiptTextBuilderTests {
    private let builder: StarReceiptTextBuilder

    init() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        builder = StarReceiptTextBuilder(dateFormatter: formatter)
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
        // Date
        #expect(receipt.contains("Date Paid"))
        #expect(receipt.contains("2023-11-14"))
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
        // Common content still renders.
        #expect(receipt.contains("My Store"))
        #expect(receipt.contains("T-Shirt"))
        #expect(receipt.contains("Total"))
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
}

private extension StarReceiptTextBuilderTests {
    func makeContent(orderNote: String?) -> ReceiptContent {
        ReceiptContent(
            parameters: CardPresentReceiptParameters(amount: 2750,
                                                     formattedAmount: "$27.50",
                                                     currency: "USD",
                                                     date: Date(timeIntervalSince1970: 1_700_000_000),
                                                     storeName: "My Store",
                                                     cardDetails: makeCardDetails(receipt: nil),
                                                     orderID: 42),
            lineItems: [
                ReceiptLineItem(title: "T-Shirt", quantity: "1", amount: "$25.00", attributes: [])
            ],
            cartTotals: [
                ReceiptTotalLine(description: "Subtotal", amount: "$25.00"),
                ReceiptTotalLine(description: "Total", amount: "$27.50")
            ],
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

    func makeCardDetails(receipt: ReceiptDetails?) -> CardPresentTransactionDetails {
        CardPresentTransactionDetails(last4: "4242",
                                      expMonth: 12,
                                      expYear: 2030,
                                      cardholderName: "Jane Doe",
                                      brand: .visa,
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
