import XCTest
@testable import Networking

class WCPayChargeMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    fileprivate let dummySiteID: Int64 = 12983476

    /// Verifies that the WCPayCharge is parsed.
    ///
    func test_WCPayCharge_map_parses_data_in_response() async throws {
        let wcpayCharge = try await mapRetrieveWCPayChargeResponse()
        XCTAssertNotNil(wcpayCharge)
    }

    /// Verifies that the WCPayCharge is parsed.
    ///
    func test_WCPayCharge_map_parses_data_in_response_without_data_envelope() async throws {
        let wcpayCharge = try await mapRetrieveWCPayChargeResponse(responseName: .cardPresentWithoutDataEnvelope)
        XCTAssertNotNil(wcpayCharge)
    }

    /// Verifies that the `siteID` is added in the mapper, because it's not provided by the API endpoint
    ///
    func test_WCPayCharge_map_includes_siteID_in_parsed_results() async throws {
        let wcpayCharge = try await mapRetrieveWCPayChargeResponse()
        XCTAssertEqual(wcpayCharge.siteID, dummySiteID)
    }

    /// Verifies that the fields are all parsed correctly for a card present payment
    ///
    func test_WCPayCharge_map_parses_all_fields_in_result_for_card_present() async throws {
        let wcpayCharge = try await mapRetrieveWCPayChargeResponse(responseName: .cardPresent)

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

    /// Verifies that the fields are all parsed correctly for an interac present payment
    ///
    func test_WCPayCharge_map_parses_all_fields_in_result_for_interac_present() async throws {
        let wcpayCharge = try await mapRetrieveWCPayChargeResponse(responseName: .interacPresent)

        let expectedCreatedDate = Date.init(timeIntervalSince1970: 1647257154) //2022-03-14 11:25:54 UTC

        let expectedPaymentMethodDetails = WCPayPaymentMethodDetails.interacPresent(
            details: .init(brand: .visa,
                           last4: "1933",
                           funding: .debit,
                           receipt: .init(accountType: .checking,
                                          applicationPreferredName: "Interac",
                                          dedicatedFileName: "A0000002771010")))

        let expectedWcpayCharge = WCPayCharge(siteID: dummySiteID,
                                              id: "ch_3KdC1s2ETjwGHy9P0Cawro7o",
                                              amount: 200,
                                              amountCaptured: 200,
                                              amountRefunded: 0,
                                              authorizationCode: "123456",
                                              captured: true,
                                              created: expectedCreatedDate,
                                              currency: "cad",
                                              paid: true,
                                              paymentIntentID: "pi_3KdC1s2ETjwGHy9P0BM3JOST",
                                              paymentMethodID: "pm_1KdC2A2ETjwGHy9PzX5ptD6N",
                                              paymentMethodDetails: expectedPaymentMethodDetails,
                                              refunded: false,
                                              status: .succeeded)
        assertEqual(wcpayCharge, expectedWcpayCharge)
    }

    /// Verifies that the fields are all parsed correctly for a card present payment
    ///
    func test_WCPayCharge_map_parses_all_fields_in_result_for_card_present_with_nulls() async throws {
        let wcpayCharge = try await mapRetrieveWCPayChargeResponse(responseName: .cardPresentMinimal)

        let expectedCreatedDate = Date.init(timeIntervalSince1970: 1643799478) //2022-02-02 10:57:58 UTC

        let expectedPaymentMethodDetails = WCPayPaymentMethodDetails.cardPresent(
            details: .init(brand: .visa,
                           last4: "4242",
                           funding: .credit,
                           receipt: .init(accountType: .credit,
                                          applicationPreferredName: nil,
                                          dedicatedFileName: nil)))

        let expectedWcpayCharge = WCPayCharge(siteID: dummySiteID,
                                              id: "ch_3KOgX62EdyGr1FMV0CSW2k48",
                                              amount: 100,
                                              amountCaptured: 100,
                                              amountRefunded: 0,
                                              authorizationCode: "123456",
                                              captured: true,
                                              created: expectedCreatedDate,
                                              currency: "usd",
                                              paid: true,
                                              paymentIntentID: "pi_3KOgX62EdyGr1FMV0HpUJ10k",
                                              paymentMethodID: "pm_1KOgXB2EdyGr1FMVucJRZLpC",
                                              paymentMethodDetails: expectedPaymentMethodDetails,
                                              refunded: false,
                                              status: .succeeded)
        XCTAssertEqual(wcpayCharge, expectedWcpayCharge)
    }

    /// Verifies that the fields are all parsed correctly for a card payment
    ///
    func test_WCPayCharge_map_parses_all_fields_in_result_for_card() async throws {
        let wcpayCharge = try await mapRetrieveWCPayChargeResponse(responseName: .card)

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
    func mapWCPayCharge(from filename: String) async throws -> WCPayCharge {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await WCPayChargeMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the CouponMapper output from `coupon.json`
    ///
    func mapRetrieveWCPayChargeResponse(responseName: ChargeResponse = .cardPresent) async throws -> WCPayCharge {
        try await mapWCPayCharge(from: responseName.rawValue)
    }

    struct FileNotFoundError: Error {}

    enum ChargeResponse: String {
        case cardPresent = "wcpay-charge-card-present"
        case cardPresentWithoutDataEnvelope = "wcpay-charge-card-present-without-data"
        case cardPresentMinimal = "wcpay-charge-card-present-minimal"
        case card = "wcpay-charge-card"
        case interacPresent = "wcpay-charge-interac-present"
    }
}
