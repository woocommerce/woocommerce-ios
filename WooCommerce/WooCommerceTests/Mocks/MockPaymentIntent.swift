@testable import Hardware

struct MockPaymentIntent {
    /// This enum was created to simplify verbose card details code in  `PaymentMethod.cardPresent` and `PaymentMethod.interacPresent`.
    enum MockPaymentMethod {
    case card, cardPresent, interacPresent, unknown

        fileprivate var toPaymentMethod: PaymentMethod {
            switch self {
            case .card:
                return .card
            case .cardPresent:
                return .cardPresent(details: MockPaymentIntent.mockCardDetails())
            case .interacPresent:
                return .interacPresent(details: MockPaymentIntent.mockCardDetails())
            case .unknown:
                return .unknown
            }
        }
    }

    static func mock(paymentMethod: MockPaymentMethod) -> PaymentIntent {
        PaymentIntent(id: "intent_id",
                      status: .requiresCapture,
                      created: Date(),
                      amount: 10000,
                      currency: "usd",
                      metadata: mockMetadata(),
                      charges: [mockCharge(paymentMethod: paymentMethod.toPaymentMethod)])
    }
}

private extension MockPaymentIntent {
    static func mockCharge(paymentMethod: PaymentMethod) -> Charge {
        Charge(id: "charge_id",
               amount: 100,
               currency: "usd",
               status: .succeeded,
               description: "charge_description",
               metadata: nil,
               paymentMethod: paymentMethod)
    }

    static func mockCardDetails() -> CardPresentTransactionDetails {
        CardPresentTransactionDetails(last4: "last4",
                                      expMonth: 1,
                                      expYear: 2021,
                                      cardholderName: "Cardholder",
                                      brand: .visa,
                                      fingerprint: "fingerprint",
                                      generatedCard: "generated_card",
                                      receipt: mockReceiptDetails(),
                                      emvAuthData: "emv_auth_data")
    }

    static func mockReceiptDetails() -> ReceiptDetails {
        ReceiptDetails(applicationPreferredName: "app_preferred_name",
                       dedicatedFileName: "dedicated_file_name",
                       authorizationResponseCode: "auth_response_code",
                       applicationCryptogram: "app_cryptogram",
                       terminalVerificationResults: "verification_result",
                       transactionStatusInformation: "transaction_status_info",
                       accountType: "account_type")
    }

    static func mockMetadata() -> [String: String] {
        PaymentIntent.initMetadata(store: "Store Name",
                                   customerName: "Customer Name",
                                   customerEmail: "customer@example.com",
                                   siteURL: "https://store.example.com",
                                   orderID: 1920,
                                   orderKey: "wc_order_0000000000000",
                                   paymentType: .single)
    }
}
