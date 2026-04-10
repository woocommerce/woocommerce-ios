import XCTest
@testable import PointOfSale
import SwiftUI

final class PointOfSaleCardPresentPaymentOnboardingViewModelTests: XCTestCase {
    func test_onDismissTap_is_invoked_when_cancelOnboarding_is_called() throws {
        // Given
        var isDismissTapInvoked = false
        let configuration = MockOnboardingViewContainerConfiguration()
        let sut = PointOfSaleCardPresentPaymentOnboardingViewModel(
            onboardingViewContainer: .init(configuration: configuration),
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
        let configuration = MockOnboardingViewContainerConfiguration()
        let sut = PointOfSaleCardPresentPaymentOnboardingViewModel(
            onboardingViewContainer: .init(configuration: configuration),
            onDismissTap: nil)
        XCTAssertNil(sut.onboardingURL)

        // When
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        configuration.showURL?(url)

        // Then
        XCTAssertEqual(sut.onboardingURL, url)
    }
}
