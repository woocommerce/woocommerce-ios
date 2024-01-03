import XCTest
@testable import Networking
@testable import WooCommerce

final class OrderNotificationViewModelTests: XCTestCase {

    func test_view_model_extract_information_correctly() {
        // Given
        let note = sampleNote()
        let order = sampleOrder()

        // When
        let viewModel = OrderNotificationViewModel()
        let notificationContent = viewModel.formatContent(note: note, order: order)

        // Then
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let expectedProducts = OrderNotificationView.Content.Product(count: "3", name: "Product 1")
        let expectedContent = OrderNotificationView.Content(storeName: "My Test Store",
                                                            date: formatter.string(from: Date()),
                                                            orderNumber: "#123",
                                                            amount: "$123.23",
                                                            paymentMethod: "visa",
                                                            shippingMethod: "Pick Up",
                                                            products: [expectedProducts])

        XCTAssertEqual(notificationContent, expectedContent)
    }
}

extension OrderNotificationViewModelTests {
    func sampleNote() -> Note {
        let storeTitle = "My Test Store"
        let range = NoteRange.fake().copy(range: .init(location: 23, length: 13))
        let block = NoteBlock.fake().copy(ranges: [range], text: "You have a new Order - My Test Store")
        return Note.fake().copy(subject: [block])
    }

    func sampleOrder() -> Order {
        let item = OrderItem.fake().copy(name: "Product 1", quantity: 3)
        let shipping = ShippingLine.fake().copy(methodTitle: "Pick Up")
        return Order.fake().copy(orderID: 123,
                                 currencySymbol: "$",
                                 datePaid: Date(),
                                 total: "123.23",
                                 paymentMethodTitle: "Visa",
                                 items: [item],
                                 shippingLines: [shipping])
    }
}
