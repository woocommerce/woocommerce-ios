import Foundation
import Testing
import WooFoundation
@testable import Yosemite
@testable import Networking

struct StorageBookingToPOSBookingMapperTests {
    private let currencyFormatter: CurrencyFormatter
    private let sut: StorageBookingToPOSBookingMapper

    init() {
        currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        sut = StorageBookingToPOSBookingMapper(currencyFormatter: currencyFormatter)
    }

    // MARK: - Line Items

    @Test
    func test_buildPOSOrder_when_orderInfo_has_lineItems_then_maps_to_POSOrderItems() {
        // Given
        let lineItems = [
            BookingOrderLineItem(
                itemID: 10,
                name: "Haircut",
                productID: 100,
                variationID: 0,
                quantity: 2,
                price: NSDecimalNumber(string: "15.00"),
                subtotal: "30.00",
                total: "30.00",
                totalTax: "3.00",
                imageSrc: "https://example.com/image.jpg"
            ),
            BookingOrderLineItem(
                itemID: 11,
                name: "Beard Trim",
                productID: 101,
                variationID: 200,
                quantity: 1,
                price: NSDecimalNumber(string: "10.00"),
                subtotal: "10.00",
                total: "10.00",
                totalTax: "1.00",
                imageSrc: nil
            )
        ]
        let orderInfo = makeOrderInfo(lineItems: lineItems)
        let booking = makeBooking(orderInfo: orderInfo)

        // When
        let result = sut.map(booking: booking, resource: nil)

        // Then
        let posOrder = result?.order
        #expect(posOrder?.lineItems.count == 2)

        let firstItem = posOrder?.lineItems[0]
        #expect(firstItem?.itemID == 10)
        #expect(firstItem?.name == "Haircut")
        #expect(firstItem?.quantity == 2)
        #expect(firstItem?.price == Decimal(15))
        #expect(firstItem?.total == Decimal(30))
        #expect(firstItem?.totalTax == Decimal(3))
        #expect(firstItem?.imageSrc == "https://example.com/image.jpg")

        let secondItem = posOrder?.lineItems[1]
        #expect(secondItem?.itemID == 11)
        #expect(secondItem?.name == "Beard Trim")
        #expect(secondItem?.imageSrc == nil)
    }

    // MARK: - Refunds

    @Test
    func test_buildPOSOrder_when_orderInfo_has_refunds_then_maps_to_POSOrderRefunds() {
        // Given
        let refunds = [
            BookingOrderRefund(refundID: 5, reason: "No show", total: "-15.00"),
            BookingOrderRefund(refundID: 6, reason: nil, total: "-10.00")
        ]
        let orderInfo = makeOrderInfo(
            paymentInfo: BookingPaymentInfo(
                paymentMethodID: "cod",
                paymentMethodTitle: "Cash",
                subtotal: "40.00",
                subtotalTax: "0",
                total: "40.00",
                totalTax: "4.00"
            ),
            refunds: refunds
        )
        let booking = makeBooking(orderInfo: orderInfo)

        // When
        let result = sut.map(booking: booking, resource: nil)

        // Then
        let posOrder = result?.order
        #expect(posOrder?.refunds.count == 2)
        #expect(posOrder?.refunds[0].refundID == 5)
        #expect(posOrder?.refunds[0].reason == "No show")
        #expect(posOrder?.refunds[1].refundID == 6)
        #expect(posOrder?.refunds[1].reason == nil)
    }

    // MARK: - Customer Email

    @Test
    func test_buildPOSOrder_when_orderInfo_has_customerEmail_then_passes_to_POSOrder() {
        // Given
        let orderInfo = makeOrderInfo(customerEmail: "test@example.com")
        let booking = makeBooking(orderInfo: orderInfo)

        // When
        let result = sut.map(booking: booking, resource: nil)

        // Then
        #expect(result?.order.customerEmail == "test@example.com")
    }

    @Test
    func test_buildPOSOrder_when_orderInfo_has_nil_customerEmail_then_POSOrder_has_nil() {
        // Given
        let orderInfo = makeOrderInfo(customerEmail: nil)
        let booking = makeBooking(orderInfo: orderInfo)

        // When
        let result = sut.map(booking: booking, resource: nil)

        // Then
        #expect(result?.order.customerEmail == nil)
    }

    // MARK: - Net Amount

    @Test
    func test_buildPOSOrder_when_refunds_exist_then_calculates_formattedNetAmount() {
        // Given
        let refunds = [
            BookingOrderRefund(refundID: 1, reason: nil, total: "-10.00")
        ]
        let orderInfo = makeOrderInfo(
            paymentInfo: BookingPaymentInfo(
                paymentMethodID: "cod",
                paymentMethodTitle: "Cash",
                subtotal: "50.00",
                subtotalTax: "0",
                total: "50.00",
                totalTax: "5.00"
            ),
            refunds: refunds
        )
        let booking = makeBooking(orderInfo: orderInfo, currency: "USD")

        // When
        let result = sut.map(booking: booking, resource: nil)

        // Then
        #expect(result?.order.formattedNetAmount == "$40.00")
    }

    @Test
    func test_buildPOSOrder_when_no_refunds_then_formattedNetAmount_is_nil() {
        // Given
        let orderInfo = makeOrderInfo(refunds: [])
        let booking = makeBooking(orderInfo: orderInfo)

        // When
        let result = sut.map(booking: booking, resource: nil)

        // Then
        #expect(result?.order.formattedNetAmount == nil)
    }

    // MARK: - Line Item Quantities

    @Test
    func test_buildPOSOrder_when_lineItems_exist_then_builds_lineItemQuantitiesByProductOrVariationID() {
        // Given
        let lineItems = [
            BookingOrderLineItem(
                itemID: 1, name: "A", productID: 100, variationID: 0,
                quantity: 2, price: NSDecimalNumber(string: "10"),
                subtotal: "20", total: "20", totalTax: "0", imageSrc: nil
            ),
            BookingOrderLineItem(
                itemID: 2, name: "B", productID: 100, variationID: 201,
                quantity: 3, price: NSDecimalNumber(string: "5"),
                subtotal: "15", total: "15", totalTax: "0", imageSrc: nil
            )
        ]
        let orderInfo = makeOrderInfo(lineItems: lineItems)
        let booking = makeBooking(orderInfo: orderInfo)

        // When
        let result = sut.map(booking: booking, resource: nil)

        // Then
        let quantities = result?.order.lineItemQuantitiesByProductOrVariationID
        #expect(quantities?[100] == 2)
        #expect(quantities?[201] == 3)
    }
}

// MARK: - Helpers

private extension StorageBookingToPOSBookingMapperTests {
    func makeOrderInfo(
        statusKey: String = "completed",
        orderID: Int64 = 1,
        orderNumber: String = "1001",
        discountTotal: String = "0.00",
        customerEmail: String? = nil,
        paymentInfo: BookingPaymentInfo? = BookingPaymentInfo(
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash",
            subtotal: "25.00",
            subtotalTax: "0",
            total: "25.00",
            totalTax: "2.50"
        ),
        lineItems: [BookingOrderLineItem] = [],
        refunds: [BookingOrderRefund] = []
    ) -> BookingOrderInfo {
        BookingOrderInfo(
            statusKey: statusKey,
            orderID: orderID,
            orderNumber: orderNumber,
            dateCreated: Date(),
            datePaid: Date(),
            discountTotal: discountTotal,
            customerEmail: customerEmail,
            paymentInfo: paymentInfo,
            customerInfo: nil,
            productInfo: BookingProductInfo(name: "Test Service"),
            lineItems: lineItems,
            refunds: refunds
        )
    }

    func makeBooking(
        orderInfo: BookingOrderInfo? = nil,
        currency: String = "USD"
    ) -> Networking.Booking {
        Networking.Booking(
            siteID: 1,
            bookingID: 1,
            allDay: false,
            cost: "25.00",
            customerID: 1,
            dateCreated: Date(),
            dateModified: nil,
            endDate: Date(),
            googleCalendarEventID: nil,
            orderID: 1,
            orderItemID: 1,
            parentID: 0,
            productID: 100,
            resourceID: 0,
            startDate: Date(),
            statusKey: "confirmed",
            attendanceStatusKey: "",
            localTimezone: "UTC",
            currency: currency,
            orderInfo: orderInfo,
            note: ""
        )
    }
}
