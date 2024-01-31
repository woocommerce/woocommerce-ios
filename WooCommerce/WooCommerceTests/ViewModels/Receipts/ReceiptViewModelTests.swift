import XCTest
import Yosemite
@testable import WooCommerce

final class ReceiptViewModelTests: XCTestCase {

    func test_receiptViewModel_returns_expected_receiptURLString_property() {
        // Given
        let fakeReceipt = Receipt.fake().copy(receiptURL: "https://mywootestingstore.com/transient/12345",
                                              expirationDate: "2024-01-27")

        // When
        let receiptViewModel = ReceiptViewModel(receipt: fakeReceipt)

        // Then
        XCTAssertEqual(receiptViewModel.receiptURLString, fakeReceipt.receiptURL)
    }

    func test_receiptViewModel_returns_expected_URLRequest_for_a_given_receipt() {
        // Given
        let fakeReceipt = Receipt.fake().copy(receiptURL: "https://mywootestingstore.com/transient/12345",
                                              expirationDate: "2024-01-27")
        guard let validURL = URL(string: fakeReceipt.receiptURL) else {
            return XCTFail("Invalid URL")
        }
        let expectedURLRequest = URLRequest(url: validURL)

        // When
        let receiptViewModel = ReceiptViewModel(receipt: fakeReceipt)

        // Then
        XCTAssertEqual(receiptViewModel.receiptRequest, expectedURLRequest)
    }
}
