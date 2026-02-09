import Testing
@testable import Hardware

/// Tests the mapping between ReceiptDetails and SCPReceiptDetails
struct `Receipt Details Tests` {
    @Test func `card receipts details maps app preferred name`() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.applicationPreferredName == mockDetails.applicationPreferredName)
    }

    @Test func `card receipts details maps dedicated file name`() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.dedicatedFileName == mockDetails.dedicatedFileName)
    }

    @Test func `card receipts details maps auth response code`() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.authorizationResponseCode == mockDetails.authorizationResponseCode)
    }

    @Test func `card receipts details maps application cryptogram`() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.applicationCryptogram == mockDetails.applicationCryptogram)
    }

    @Test func `card receipts details maps terminal verification results`() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.terminalVerificationResults == mockDetails.terminalVerificationResults)
    }

    @Test func `card receipts details maps tsi`() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.transactionStatusInformation == mockDetails.transactionStatusInformation)
    }

    @Test func `card receipts details maps account type`() {
        let mockDetails = MockStripeReceiptDetails.mock()
        let details = ReceiptDetails(receiptDetails: mockDetails)

        #expect(details?.accountType == mockDetails.accountType)
    }

    @Test func `card receipts details initializes to nil with nil data`() {
        let details = ReceiptDetails(receiptDetails: nil)

        #expect(details == nil)
    }
}
