import XCTest
@testable import PointOfSale

final class PointOfSaleCardPresentPaymentCaptureErrorMessageViewModelTests: XCTestCase {
    func test_onAppear_when_capture_status_is_unknown_then_shows_information_sheet() {
        // Given
        let sut = PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel(tryAgainButtonAction: {}, newOrderButtonAction: {})
        XCTAssertFalse(sut.showsInfoSheet)

        // When
        sut.onAppear()

        // Then
        XCTAssertTrue(sut.showsInfoSheet)
    }
}
