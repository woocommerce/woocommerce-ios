import XCTest
@testable import WooCommerce

@MainActor
final class WPComPushNotificationsBenefitsViewModelTests: XCTestCase {

    // MARK: - Variant

    func test_default_variant_is_connect() {
        // Given
        let viewModel = makeViewModel()

        // Then
        XCTAssertEqual(viewModel.variant, .connect)
    }

    func test_variant_is_pluginUpdate_when_passed_in_init() {
        // Given
        let viewModel = makeViewModel(variant: .pluginUpdate)

        // Then
        XCTAssertEqual(viewModel.variant, .pluginUpdate)
    }

    // MARK: - Helpers

    private func makeViewModel(variant: WPComPushNotificationsBenefitsViewModel.Variant = .connect) -> WPComPushNotificationsBenefitsViewModel {
        WPComPushNotificationsBenefitsViewModel(
            variant: variant,
            onDismiss: {}
        )
    }
}

// MARK: - WPComPushNotificationsBenefitsViewModel.Variant Equatable

extension WPComPushNotificationsBenefitsViewModel.Variant: Equatable {}
