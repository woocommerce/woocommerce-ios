import XCTest
@testable import Networking

class WCPayChargeMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    fileprivate let dummySiteID: Int64 = 12983476

    /// Verifies that the WCPayCharge is parsed.
    ///
    func test_WCPayCharge_map_parses_all_coupons_in_response() throws {
        let wcpayCharge = try mapRetrieveWCPayChargeResponse()
        XCTAssertNotNil(wcpayCharge)
    }

    /// Verifies that the `siteID` is added in the mapper, because it's not provided by the API endpoint
    ///
    func test_WCPayCharge_map_includes_siteID_in_parsed_results() throws {
        let wcpayCharge = try mapRetrieveWCPayChargeResponse()
        XCTAssertEqual(wcpayCharge.siteID, dummySiteID)
    }

    /// Verifies that the fields are all parsed correctly for a card present payment
    ///
    func test_WCPayCharge_map_parses_all_fields_in_result_for_card_present() throws {
        let wcpayCharge = try mapRetrieveWCPayChargeResponse(responseName: .cardPresent)

        let expectedCreatedDate = Date.init(timeIntervalSince1970: 1643280767) //2022-01-27 10:52:47 UTC

        let expectedPaymentMethodDetails = WCPayPaymentMethodDetails.cardPresent(
            details: .init(brand: .visa,
                           last4: "9969",
                           funding: .credit,
                           receipt: .init(accountType: .credit,
                                          applicationPreferredName: "Stripe Credit",
                                          dedicatedFileName: "A000000003101001")))

        let expectedWcpayCharge = WCPayCharge(siteID: dummySiteID,
                                              id: "ch_3KMVap2EdyGr1FMV1uKJEWtg",
                                              amount: 1800,
                                              amountCaptured: 1800,
                                              amountRefunded: 0,
                                              authorizationCode: "123456",
                                              captured: true,
                                              created: expectedCreatedDate,
                                              currency: "usd",
                                              paid: true,
                                              paymentIntentID: "pi_3KMVap2EdyGr1FMV16atNgK9",
                                              paymentMethodID: "pm_1KMVas2EdyGr1FMVnleuPovE",
                                              paymentMethodDetails: expectedPaymentMethodDetails,
                                              refunded: false,
                                              status: .succeeded)
        XCTAssertEqual(wcpayCharge, expectedWcpayCharge)
    }

    /// Verifies that the fields are all parsed correctly for a card payment
    ///
    func test_WCPayCharge_map_parses_all_fields_in_result_for_card() throws {
        let wcpayCharge = try mapRetrieveWCPayChargeResponse(responseName: .card)

        let expectedCreatedDate = Date.init(timeIntervalSince1970: 1643378348) //2022-01-28 13:59:08 UTC

        let expectedPaymentMethodDetails = WCPayPaymentMethodDetails.card(
            details: .init(brand: .amex, last4: "1111", funding: .credit))

        let expectedWcpayCharge = WCPayCharge(siteID: dummySiteID,
                                              id: "ch_3KMuym2EdyGr1FMV0uQZeFqm",
                                              amount: 3330,
                                              amountCaptured: 3330,
                                              amountRefunded: 0,
                                              authorizationCode: nil,
                                              captured: true,
                                              created: expectedCreatedDate,
                                              currency: "usd",
                                              paid: true,
                                              paymentIntentID: "pi_3KMuym2EdyGr1FMV0TtJrfac",
                                              paymentMethodID: "pm_1KMuyk2EdyGr1FMVYAz48aiQ",
                                              paymentMethodDetails: expectedPaymentMethodDetails,
                                              refunded: false,
                                              status: .succeeded)
        XCTAssertEqual(wcpayCharge, expectedWcpayCharge)
    }
}


// MARK: - Test Helpers
///
private extension WCPayChargeMapperTests {

    /// Returns the CouponMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapWCPayCharge(from filename: String) throws -> WCPayCharge {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try WCPayChargeMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the CouponMapper output from `coupon.json`
    ///
    func mapRetrieveWCPayChargeResponse(responseName: ChargeResponse = .cardPresent) throws -> WCPayCharge {
        return try mapWCPayCharge(from: responseName.rawValue)
    }

    struct FileNotFoundError: Error {}

    enum ChargeResponse: String {
        case cardPresent = "wcpay-charge-card-present"
        case card = "wcpay-charge-card"
    }
}
