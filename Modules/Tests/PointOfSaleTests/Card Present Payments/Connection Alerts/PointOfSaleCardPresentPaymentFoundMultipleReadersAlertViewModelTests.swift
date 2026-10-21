import XCTest
@testable import PointOfSale

final class PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModelTests: XCTestCase {
    func test_connect_when_reader_is_selected_then_reports_selected_reader() {
        // Given
        var selections: [String?] = []
        let sut = PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel(
            readerIDs: ["reader-a", "reader-b"], selectionHandler: { selections.append($0) })

        // When
        sut.connect("reader-b")

        // Then
        XCTAssertEqual(selections, ["reader-b"])
    }

    func test_cancelSearch_when_search_is_cancelled_then_reports_no_selection() {
        // Given
        var selections: [String?] = []
        let sut = PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel(
            readerIDs: ["reader-a"], selectionHandler: { selections.append($0) })

        // When
        sut.cancelSearch()

        // Then
        XCTAssertEqual(selections, [nil])
    }
}
