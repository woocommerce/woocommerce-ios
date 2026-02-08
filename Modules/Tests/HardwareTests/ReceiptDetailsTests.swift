import Testing
@testable import Hardware

/// Tests the mapping between ReceiptDetails and SCPReceiptDetails
@Suite("Receipt Details Tests")
struct ReceiptDetailsTests {
    @Test func test_card_receipts_details_maps_app_preferred_name() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.applicationPreferredName == mockDetails.applicationPreferredName)
    }

    @Test func test_card_receipts_details_maps_dedicated_file_name() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.dedicatedFileName == mockDetails.dedicatedFileName)
    }

    @Test func test_card_receipts_details_maps_auth_response_code() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.authorizationResponseCode == mockDetails.authorizationResponseCode)
    }

    @Test func test_card_receipts_details_maps_application_cryptogram() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.applicationCryptogram == mockDetails.applicationCryptogram)
    }

    @Test func test_card_receipts_details_maps_terminal_verification_results() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.terminalVerificationResults == mockDetails.terminalVerificationResults)
    }

    @Test func test_card_receipts_details_maps_tsi() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.transactionStatusInformation == mockDetails.transactionStatusInformation)
    }

    @Test func test_card_receipts_details_maps_account_type() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.accountType == mockDetails.accountType)
    }

    @Test func test_card_receipts_details_initializes_to_nil_with_nil_data() {
        let details = ReceiptDetails(receiptDetails: nil)

        #expect(details == nil)
    }
}
