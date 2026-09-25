import Foundation
import Testing
@testable import Networking

struct POSCashSessionResponseTests {
    @Test
    func test_decode_when_drawer_name_is_present_then_preserves_it() throws {
        // Given
        let response = responseData(drawerField: "\"Front counter\"")

        // When
        let session = try JSONDecoder().decode(POSCashSessionResponse.self, from: response)

        // Then
        #expect(session.drawerID == "Front counter")
    }

    @Test
    func test_decode_when_drawer_name_is_null_then_keeps_it_absent() throws {
        // Given
        let response = responseData(drawerField: "null")

        // When
        let session = try JSONDecoder().decode(POSCashSessionResponse.self, from: response)

        // Then
        #expect(session.drawerID == nil)
    }

    @Test
    func test_decode_when_drawer_field_is_missing_then_keeps_it_absent() throws {
        // Given
        let response = responseData(drawerField: nil)

        // When
        let session = try JSONDecoder().decode(POSCashSessionResponse.self, from: response)

        // Then
        #expect(session.drawerID == nil)
    }

    private func responseData(drawerField: String?) -> Data {
        let drawerEntry = drawerField.map { "\"drawer_id\": \($0)," } ?? ""
        return Data("""
        {
          "id": 42,
          "device_id": "pos-1",
          \(drawerEntry)
          "status": "closed",
          "revision": 2,
          "currency": "USD",
          "currency_precision": 2,
          "opening_amount": "100.00",
          "cash_sales_total": "20.00",
          "cash_refunds_total": "0.00",
          "paid_in_total": "0.00",
          "paid_out_total": "0.00",
          "expected_amount": "120.00",
          "counted_amount": "120.00",
          "variance": "0.00",
          "note": null,
          "date_created_gmt": "2026-09-25T10:00:00Z",
          "date_closed_gmt": "2026-09-25T11:00:00Z",
          "opened_by_name": "Thomas",
          "closed_by_name": "Maria"
        }
        """.utf8)
    }
}
