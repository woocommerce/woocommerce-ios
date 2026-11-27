import Testing
import UIKit
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
struct PaymentMethodsHostingControllerTests {
    @Test func test_dismiss_when_screen_closes_in_code_and_by_swipe_then_calls_onDismiss_once() {
        // Given
        let dependencies = PaymentMethodsViewModel.Dependencies(stores: MockStoresManager(sessionManager: .testingInstance),
                                                               storage: MockStorageManager())
        let viewModel = PaymentMethodsViewModel(total: "12",
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                channel: .storeManagement,
                                                dependencies: dependencies)
        let viewController = PaymentMethodsHostingController(viewModel: viewModel)
        var dismissCount = 0
        viewController.onDismiss = {
            dismissCount += 1
        }

        // When
        viewController.rootView.dismiss()
        viewController.presentationControllerDidDismiss(UIPresentationController(presentedViewController: viewController, presenting: nil))

        // Then
        #expect(dismissCount == 1)
    }
}
