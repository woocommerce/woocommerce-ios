import XCTest
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentOnboardingViewModelTests: XCTestCase {
    func test_onDismissTap_is_invoked_when_cancelOnboarding_is_called() throws {
        // Given
        var isDismissTapInvoked = false
        let sut = PointOfSaleCardPresentPaymentOnboardingViewModel(onboardingViewModel: .init(fixedState: .genericError),
            onDismissTap: {
                isDismissTapInvoked = true
            })

        // When
        sut.cancelOnboarding()

        // Then
        XCTAssertTrue(isDismissTapInvoked)
    }

    func test_onboardingURL_is_set_when_onboarding_vm_showURL_is_invoked() throws {
        // Given
        let onboardingViewModel = CardPresentPaymentsOnboardingViewModel(fixedState: .noConnectionError)
        let sut = PointOfSaleCardPresentPaymentOnboardingViewModel(onboardingViewModel: onboardingViewModel, onDismissTap: nil)
        XCTAssertNil(sut.onboardingURL)

        // When
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        onboardingViewModel.showURL?(url)

        // Then
        XCTAssertEqual(sut.onboardingURL, url)
    }
}
