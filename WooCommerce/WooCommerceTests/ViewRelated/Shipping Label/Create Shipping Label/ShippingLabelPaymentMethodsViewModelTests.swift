import XCTest
@testable import WooCommerce
import Yosemite

class ShippingLabelPaymentMethodsViewModelTests: XCTestCase {

    func test_properties_return_expected_values() {
        // Given
        let paymentMethod = ShippingLabelPaymentMethod.fake().copy()
        let settings = ShippingLabelAccountSettings.fake().copy(storeOwnerDisplayName: "Display Name",
                                                                storeOwnerUsername: "admin",
                                                                storeOwnerWpcomUsername: "username",
                                                                storeOwnerWpcomEmail: "user@example.com",
                                                                paymentMethods: [paymentMethod],
                                                                selectedPaymentMethodID: 11743265,
                                                                isEmailReceiptsEnabled: true)
        let viewModel = ShippingLabelPaymentMethodsViewModel(accountSettings: settings)

        // Then
        XCTAssertEqual(viewModel.isEmailReceiptsEnabled, true)
        XCTAssertEqual(viewModel.paymentMethods, [paymentMethod])
        XCTAssertEqual(viewModel.selectedPaymentMethodID, 11743265)
        XCTAssertEqual(viewModel.storeOwnerDisplayName, "Display Name")
        XCTAssertEqual(viewModel.storeOwnerUsername, "admin")
        XCTAssertEqual(viewModel.storeOwnerWPcomEmail, "user@example.com")
        XCTAssertEqual(viewModel.storeOwnerWPcomUsername, "username")
    }

    func test_didSelectPaymentMethod_updates_selectedPaymentMethodID() {
        // Given
        let viewModel = ShippingLabelPaymentMethodsViewModel(accountSettings: ShippingLabelAccountSettings.fake().copy())

        // When
        viewModel.didSelectPaymentMethod(withID: 12345)

        // Then
        XCTAssertEqual(viewModel.selectedPaymentMethodID, 12345)
    }

    func test_isDoneButtonEnabled_returns_expected_value() {
        // Given
        let paymentMethod = ShippingLabelPaymentMethod.fake().copy()
        let settings = ShippingLabelAccountSettings.fake().copy(paymentMethods: [paymentMethod],
                                                                selectedPaymentMethodID: 12345,
                                                                isEmailReceiptsEnabled: false)
        let viewModel = ShippingLabelPaymentMethodsViewModel(accountSettings: settings)

        // Then
        XCTAssertFalse(viewModel.isDoneButtonEnabled())

        // When only payment method changes
        viewModel.selectedPaymentMethodID = 54321
        viewModel.isEmailReceiptsEnabled = false

        // Then
        XCTAssertTrue(viewModel.isDoneButtonEnabled())

        // When only email receipts setting changes
        viewModel.selectedPaymentMethodID = 12345
        viewModel.isEmailReceiptsEnabled = true

        // Then
        XCTAssertTrue(viewModel.isDoneButtonEnabled())

        // When both payment method and email receipts setting change
        viewModel.selectedPaymentMethodID = 54321
        viewModel.isEmailReceiptsEnabled = true

        // Then
        XCTAssertTrue(viewModel.isDoneButtonEnabled())
    }
}
