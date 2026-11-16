import Foundation
import Testing
@testable import NetworkingCore

struct OrderPaymentDetailsMapperTests {
    @Test(arguments: [true, false])
    func test_map_when_order_has_internal_intent_then_retains_it(enveloped: Bool) throws {
        // Given
        let order = """
        {"id":560,"date_paid":null,"meta_data":[
            {"id":1,"key":"_intent_id","value":"pi_authorized"},
            {"id":2,"key":"unrelated","value":{"name":"value"}}
        ]}
        """
        let data = Data((enveloped ? "{\"data\":\(order)}" : order).utf8)

        // When
        let details = try OrderPaymentDetailsMapper().map(response: data)

        // Then
        #expect(details.orderID == 560)
        #expect(details.wooPaymentsIntentID == "pi_authorized")
        #expect(!details.isPaid)
    }

    @Test(arguments: ["{\"id\":560,\"meta_data\":[]}", "{\"id\":560,\"date_paid\":null}"])
    func test_map_when_payment_fields_are_missing_then_throws(response: String) {
        // Given
        let data = Data(response.utf8)

        // When / Then
        #expect(throws: DecodingError.self) {
            try OrderPaymentDetailsMapper().map(response: data)
        }
    }

    @Test func test_map_when_order_has_paid_date_then_reports_paid() throws {
        // Given
        let data = Data(#"{"id":560,"date_paid":"2026-11-07T20:11:55","meta_data":[]}"#.utf8)

        // When
        let details = try OrderPaymentDetailsMapper().map(response: data)

        // Then
        #expect(details.isPaid)
    }
}
