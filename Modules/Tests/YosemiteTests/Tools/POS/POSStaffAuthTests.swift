import Foundation
import Testing
@testable import Yosemite

struct POSStaffAuthTests {
    @Test
    func headers_when_no_initiator_then_only_request_and_staff_headers_are_present() {
        // Given
        let auth = POSStaffAuth(actorUserID: 42)

        // When
        let headers = auth.headers

        // Then
        #expect(headers == [
            "X-WC-POS-Request": "1",
            "X-WC-POS-Staff-Id": "42"
        ])
    }

    @Test
    func headers_when_initiator_present_then_initiator_header_is_added() {
        // Given — an override refund: the approving manager is the actor, the cashier the initiator
        let auth = POSStaffAuth(actorUserID: 7, initiatorUserID: 99)

        // When
        let headers = auth.headers

        // Then
        #expect(headers == [
            "X-WC-POS-Request": "1",
            "X-WC-POS-Staff-Id": "7",
            "X-WC-POS-Initiator-Id": "99"
        ])
    }
}
