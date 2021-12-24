import XCTest
@testable import Hardware

/// Tests the mapping between ReceiptDetails and SCPReceiptDetails
final class ReceiptDetailsTests: XCTestCase {
    func test_card_receipts_details_maps_app_preferred_name() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        XCTAssertEqual(details?.applicationPreferredName, mockDetails.applicationPreferredName)
    }

    func test_card_receipts_details_maps_dedicated_file_name() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        XCTAssertEqual(details?.dedicatedFileName, mockDetails.dedicatedFileName)
    }

    func test_card_receipts_details_maps_auth_response_code() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        XCTAssertEqual(details?.authorizationResponseCode, mockDetails.authorizationResponseCode)
    }

    func test_card_receipts_details_maps_application_cryptogram() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        XCTAssertEqual(details?.applicationCryptogram, mockDetails.applicationCryptogram)
    }

    func test_card_receipts_details_maps_terminal_verification_results() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        XCTAssertEqual(details?.terminalVerificationResults, mockDetails.terminalVerificationResults)
    }

    func test_card_receipts_details_maps_tsi() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        XCTAssertEqual(details?.transactionStatusInformation, mockDetails.transactionStatusInformation)
    }

    func test_card_receipts_details_maps_account_type() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        XCTAssertEqual(details?.accountType, mockDetails.accountType)
    }

    func test_card_receipts_details_initializes_to_nil_with_nil_data() {
        let details = ReceiptDetails(receiptDetails: nil)

        XCTAssertNil(details)
    }
}
