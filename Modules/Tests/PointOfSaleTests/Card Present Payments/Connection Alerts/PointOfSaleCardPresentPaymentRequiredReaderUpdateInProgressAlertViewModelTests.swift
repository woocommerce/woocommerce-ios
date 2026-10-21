import XCTest
@testable import PointOfSale

final class PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModelTests: XCTestCase {
    func test_progress_when_half_complete_then_shows_percentage_and_remains_incomplete() {
        // Given / When
        let sut = PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel(progress: 0.5, cancel: nil)

        // Then
        XCTAssertEqual(sut.progressTitle, "50% complete")
        XCTAssertFalse(sut.isComplete)
    }

    func test_progress_when_complete_or_above_then_reports_complete() {
        // Given
        for progress: Float in [1.0, 1.1] {
            // When
            let sut = PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel(progress: progress, cancel: nil)

            // Then
            XCTAssertTrue(sut.isComplete)
        }
    }
}
