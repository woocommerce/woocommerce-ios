import Testing
import UIKit
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
struct PaymentMethodsHostingControllerTests {
    @Test(arguments: [false, true])
    func test_dismiss_when_screen_closes_then_calls_onDismiss_once(swipeFirst: Bool) {
        // Given
        let dependencies = PaymentMethodsViewModel.Dependencies(stores: MockStoresManager(sessionManager: .testingInstance),
                                                               storage: MockStorageManager())
        let viewModel = PaymentMethodsViewModel(total: "12",
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                channel: .storeManagement,
                                                dependencies: dependencies)
        var dismissCount = 0
        let viewController = PaymentMethodsHostingController(viewModel: viewModel) {
            dismissCount += 1
        }

        let presentation = UIPresentationController(presentedViewController: viewController, presenting: nil)

        // When
        if swipeFirst {
            viewController.presentationControllerDidDismiss(presentation)
        } else {
            viewController.rootView.dismiss()
        }
        let countAfterFirstDismiss = dismissCount
        viewController.rootView.dismiss()
        viewController.presentationControllerDidDismiss(presentation)

        // Then
        #expect(countAfterFirstDismiss == 1)
        #expect(dismissCount == 1)
    }
}
