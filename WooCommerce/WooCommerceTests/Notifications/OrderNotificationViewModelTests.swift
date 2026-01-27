import XCTest
@testable import Networking
@testable import WooCommerce

final class OrderNotificationViewModelTests: XCTestCase {

    func test_view_model_extract_information_correctly() {
        // Given
        let storeName = "Miffy Store"
        let order = sampleOrder()

        // When
        let viewModel = OrderNotificationViewModel()
        let notificationContent = viewModel.formatContent(order: order, storeName: storeName)

        // Then
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let expectedProducts = OrderNotificationView.Content.Product(count: "3", name: "Product 1")
        let expectedContent = OrderNotificationView.Content(storeName: "Miffy Store",
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
