import XCTest

@testable import Networking

final class PaymentGatewayListMapperTests: XCTestCase {

    /// Site sample identifier.
    ///
    static let sampleSiteID: Int64 = 123

    func test_payment_gateway_list_is_decoded_from_json_response() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("payment-gateway-list"))
        let expectedGateways = [Self.bankTransferGateway, Self.checkGateway, Self.cashGateway, Self.paypalGateway]

        // When
        let gateways = try PaymentGatewayListMapper(siteID: Self.sampleSiteID).map(response: jsonData)

        // Then
        XCTAssertEqual(gateways, expectedGateways)
    }
}

// MARK: Private Helpers
private extension PaymentGatewayListMapperTests {

    static let bankTransferGateway = PaymentGateway(siteID: sampleSiteID,
                                                    gatewayID: "bacs",
                                                    title: "Direct bank transfer",
                                                    description: "Make your payment directly into our bank account. " +
                                                        "Please use your Order ID as the payment reference. " +
                                                        "Your order will not be shipped until the funds have cleared in our account.",
                                                    enabled: false,
                                                    features: [.products])

    static let checkGateway = PaymentGateway(siteID: sampleSiteID,
                                             gatewayID: "cheque",
                                             title: "Check payments",
                                             description: "Please send a check to Store Name, Store Street, Store Town, Store State / County, Store Postcode.",
                                             enabled: false,
                                             features: [.products])

    static let cashGateway = PaymentGateway(siteID: sampleSiteID,
                                            gatewayID: "cod",
                                            title: "Cash on delivery",
                                            description: "Pay with cash upon delivery.",
                                            enabled: true,
                                            features: [.products])

    static let paypalGateway = PaymentGateway(siteID: sampleSiteID,
                                              gatewayID: "paypal",
                                              title: "PayPal",
                                              description: "Pay via PayPal; you can pay with your credit card if you don't have a PayPal account.",
                                              enabled: false,
                                              features: [.products, .refunds])
}
