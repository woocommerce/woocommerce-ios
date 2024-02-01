import XCTest
@testable import Yosemite
@testable import Storage
@testable import Networking
@testable import Hardware

/// ReceiptStore Unit Tests
///
final class ReceiptStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock receipt printing service.
    private var receiptPrinterService: MockReceiptPrinterService!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        receiptPrinterService = MockReceiptPrinterService()
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil
        receiptPrinterService = nil

        super.tearDown()
    }

    func test_print_calls_print_in_service() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder()

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        XCTAssertTrue(receiptPrinterService.printWasCalled)
    }

    func test_print_calls_print_in_passing_expected_parameters() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(amount: 10000, currency: "usd", charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder()

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let parametersProvided = receiptPrinterService.contentProvided

        XCTAssertEqual(mockParameters.amount, parametersProvided?.parameters.amount)
        XCTAssertEqual(mockOrder.currency, parametersProvided?.parameters.currency)
        XCTAssertEqual("$100.00", parametersProvided?.parameters.formattedAmount)
    }

    func test_print_callsPrint_passing_TotalAmountPaid() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(amount: 10000, charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder()

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let amountPaidLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.amountPaidLineDescription
        }
        XCTAssertEqual("$100.00", amountPaidLine?.amount)
    }

    func test_print_callsPrint_passing_TotalTaxes() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(currency: "USD", charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder(discountTax: "1.21", shippingTax: "0.50", totalTax: "10.71")

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualTaxLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.totalTaxLineDescription
        }
        let expectedValue = "$\(mockOrder.totalTax)"
        XCTAssertEqual(expectedValue, actualTaxLine?.amount)
    }

    func test_print_OrderWithoutTaxes_DoesNotIncludeTaxesInReceiptContent() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder(totalTax: "0.00")

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualTaxLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.totalTaxLineDescription
        }
        XCTAssertNil(actualTaxLine)
    }

    func test_print_callsPrint_passing_Shipping() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(currency: "USD", charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder(shippingTotal: "5.50")

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualShippingLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.shippingLineDescription
        }
        let expectedValue = "$\(mockOrder.shippingTotal)"

        XCTAssertEqual(expectedValue, actualShippingLine?.amount)
    }

    func test_print_OrderWithoutShipping_DoesNotIncludeShippingInReceiptContent() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder(shippingTotal: "0.00")

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualShippingLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.shippingLineDescription
        }
        XCTAssertNil(actualShippingLine)
    }

    func test_print_callsPrint_passing_Discount() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let coupons = [OrderCouponLine(couponID: 123, code: "5off", discount: "5.00", discountTax: "0.00")]
        let mockOrder = makeOrder(discountTotal: "5.00", coupons: coupons)

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualDiscountLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description.starts(with: expectedDiscountLineDescription())
        }
        XCTAssertEqual(actualDiscountLine?.amount, "-5.00")
    }

    func test_print_OrderWithoutDiscountOrCoupons_DoesNotIncludeDiscountInReceiptContent() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder(discountTotal: "0.00", coupons: [])

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualDiscountLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description.starts(with: expectedDiscountLineDescription())
        }
        XCTAssertNil(actualDiscountLine)
    }

    func test_print_OrderWithoutDiscount_WithCoupon_IncludesCouponInReceiptContent() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let coupons = [OrderCouponLine(couponID: 123, code: "FreeShipping", discount: "0.00", discountTax: "0.00")]
        let mockOrder = makeOrder(discountTotal: "0.00", coupons: coupons)

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualDiscountLine = try XCTUnwrap(receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description.starts(with: expectedDiscountLineDescription())
        })

        XCTAssert(actualDiscountLine.description.contains("(FreeShipping)"))
        XCTAssertEqual(actualDiscountLine.amount, "0.00")
    }

    func test_print_OrderWithDiscountFromMultipleCoupons_ListsCouponsInReceiptContent() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let coupons = [OrderCouponLine(couponID: 123, code: "1off", discount: "1.00", discountTax: "0.00"),
                       OrderCouponLine(couponID: 1901, code: "AVQW112", discount: "12.50", discountTax: "0.00")]
        let mockOrder = makeOrder(discountTotal: "13.50", coupons: coupons)

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualDiscountLine = try XCTUnwrap(receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description.starts(with: expectedDiscountLineDescription())
        })

        XCTAssert(actualDiscountLine.description.contains("(1off, AVQW112)"))
    }

    func test_print_callsPrint_passing_Fees() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let fees = [makeFee(amount: "5.00"), makeFee(amount: "15.50")]
        let mockOrder = makeOrder(fees: fees)

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualFeesLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.feesLineDescription
        }
        XCTAssertEqual(actualFeesLine?.amount, "$20.50")
    }

    func test_print_OrderWithoutFees_DoesNotIncludeFeesInReceiptContent() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder(fees: [])

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualFeesLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.feesLineDescription
        }
        XCTAssertNil(actualFeesLine)
    }

    func test_print_OrderWithZeroFees_DoesNotIncludeFeesInReceiptContent() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder(fees: [makeFee(amount: "0.00")])

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let actualFeesLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.feesLineDescription
        }
        XCTAssertNil(actualFeesLine)
    }

    func test_print_callsPrint_passing_LineItemsTotal_calculatedUsing_UndiscountedSubtotals() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let items = [makeItem(subtotal: "20.00", total: "12.50"), makeItem(subtotal: "10.00", total: "10.00")]
        let mockOrder = makeOrder(items: items)

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        let lineItemsTotalLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.productTotalLineDescription
        }
        XCTAssertEqual("$30.00", lineItemsTotalLine?.amount)
    }

    func test_generateContent_callsGenerate_passingUnmodified_customerNote() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let expectedNote = "<a href=\"https://example.com\">This note has a link</a>"
        let mockOrder = makeOrder(customerNote: expectedNote)

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let content: String = waitFor { promise in
            let action = ReceiptAction.generateContent(
                order: mockOrder,
                parameters: mockParameters,
                onContent: { content in
                    promise(content)
                })
            receiptStore.onAction(action)
        }

        // Then
        XCTAssert(content.contains(expectedNote))
    }

    func test_print_callsPrint_passingHTMLStripped_customerNote() throws {
        // Given
        let mockIntent = PaymentIntent.fake().copy(charges: [Mocks.cardPresentCharge])
        let mockParameters = try XCTUnwrap(mockIntent.receiptParameters())
        let mockOrder = makeOrder(customerNote: "<a href=\"https://example.com\">This note has a link</a>")

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        // When
        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        // Then
        XCTAssertEqual(receiptPrinterService.contentProvided?.orderNote, "This note has a link")
    }

    func test_retrieveReceipt_when_orderID_matches_route_then_returns_valid_receipt_with_expected_fields() throws {
        // Given
        let sampleOrderID: Int64 = 123
        let mockOrder = Order.fake().copy(orderID: sampleOrderID)
        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())
        let expectedReceiptURL = "https://mywootestingstore.com/wc/file/transient/7e811be40195b17f82604592ed26b694868807"
        let expectedReceiptExpirationDate = "2024-01-27"

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/receipt", filename: "receipt")

        // When
        let expectedResult: Result<Receipt, Error> = waitFor { promise in
            let action = ReceiptAction.retrieveReceipt(order: mockOrder, onCompletion: { result in
                promise(result)
            })
            receiptStore.onAction(action)
        }

        // Then
        let expectedReceipt = try expectedResult.get()
        assertEqual(expectedReceiptURL, expectedReceipt.receiptURL)
        assertEqual(expectedReceiptExpirationDate, expectedReceipt.expirationDate)
    }

    func test_retrieveReceipt_when_orderID_does_not_match_route_then_returns_error() throws {
        // Given
        let sampleOrderID: Int64 = 987
        let mockOrder = Order.fake().copy(orderID: sampleOrderID)
        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        network.simulateResponse(requestUrlSuffix: "orders/123/receipt", filename: "receipt")

        // When
        let expectedResult: Result<Receipt, Error> = waitFor { promise in
            let action = ReceiptAction.retrieveReceipt(order: mockOrder, onCompletion: { result in
                promise(result)
            })
            receiptStore.onAction(action)
        }

        // Then
        let expectedError = expectedResult.failure
        XCTAssertNotNil(expectedError)
    }
}


private extension ReceiptStoreTests {
    func makeOrder(customerNote: String? = nil,
                   discountTotal: String = "",
                   discountTax: String = "",
                   shippingTotal: String = "",
                   shippingTax: String = "",
                   totalTax: String = "",
                   items: [Yosemite.OrderItem] = [],
                   coupons: [OrderCouponLine] = [],
                   fees: [Yosemite.OrderFeeLine] = [],
                   taxes: [Yosemite.OrderTaxLine] = []) -> Networking.Order {
        Order.fake().copy(siteID: 1234,
                          status: .custom(""),
                          currency: "usd",
                          customerNote: customerNote,
                          discountTotal: discountTotal,
                          discountTax: discountTax,
                          shippingTotal: shippingTotal,
                          shippingTax: shippingTax,
                          total: "100.00",
                          totalTax: totalTax,
                          items: items,
                          coupons: coupons,
                          fees: fees,
                          taxes: taxes)
    }

    func expectedDiscountLineDescription() -> String {
        return String.localizedStringWithFormat(ReceiptContent.Localization.discountLineDescription, "")
    }

    func makeFee(id: Int64 = 123,
                 name: String = "Fee",
                 amount: String) -> Yosemite.OrderFeeLine {
        Yosemite.OrderFeeLine(feeID: id,
                              name: name,
                              taxClass: "",
                              taxStatus: .none,
                              total: amount,
                              totalTax: "0",
                              taxes: [],
                              attributes: [])
    }

    func makeItem(id: Int64 = 12345,
                  quantity: Decimal = Decimal(1),
                  price: NSDecimalNumber = NSDecimalNumber(10),
                  subtotal: String = "15",
                  total: String = "10") -> Yosemite.OrderItem {
        Yosemite.OrderItem(itemID: id,
                           name: "Product",
                           productID: 1234,
                           variationID: 123456,
                           quantity: quantity,
                           price: price,
                           sku: nil,
                           subtotal: subtotal,
                           subtotalTax: "",
                           taxClass: "",
                           taxes: [],
                           total: total,
                           totalTax: "",
                           attributes: [],
                           addOns: [],
                           parent: nil,
                           bundleConfiguration: [])
    }
}

private extension ReceiptStoreTests {
    enum Mocks {
        static let cardPresentCharge = Charge.fake().copy(paymentMethod: .cardPresent(details: .fake()))
    }
}
