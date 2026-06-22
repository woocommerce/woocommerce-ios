import Testing
import Foundation
@testable import Hardware

struct StarPrinterServiceTests {
    @Test func test_printReceipt_when_no_printer_connected_then_throws_printerNotConnected() async {
        // Given
        let service = StarPrinterService()
        let content = makeContent()

        // When / Then
        await #expect(throws: PrinterError.printerNotConnected) {
            try await service.printReceipt(content: content, storeInformation: .empty, cardDetails: nil)
        }
    }
}

private extension StarPrinterServiceTests {
    func makeContent() -> ReceiptContent {
        ReceiptContent(
            parameters: CardPresentReceiptParameters(amount: 2750,
                                                     formattedAmount: "$27.50",
                                                     currency: "USD",
                                                     date: Date(timeIntervalSince1970: 1_700_000_000),
                                                     storeName: "My Store",
                                                     cardDetails: makeCardDetails(),
                                                     orderID: 42),
            lineItems: [ReceiptLineItem(title: "T-Shirt", quantity: "1", amount: "$25.00", attributes: [])],
            cartTotals: [ReceiptTotalLine(description: "Total", amount: "$25.00")],
            orderNote: nil
        )
    }

    func makeCardDetails() -> CardPresentTransactionDetails {
        CardPresentTransactionDetails(last4: "4242",
                                      expMonth: 12,
                                      expYear: 2030,
                                      cardholderName: "Jane Doe",
                                      brand: .visa,
                                      availableNetworks: nil,
                                      generatedCard: nil,
                                      receipt: nil,
                                      emvAuthData: nil,
                                      wallet: nil,
                                      network: nil)
    }
}
