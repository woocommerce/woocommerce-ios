import Foundation
import Testing
@testable import Yosemite

struct POSPINRecoveryIdentityTests {
    @Test(arguments: [
        (#"{"id":7,"roles":["administrator"]}"#, POSPINRecoveryIdentity.sameEligibleAccount),
        (#"{"data":{"id":7,"roles":["shop_manager"]}}"#, .sameEligibleAccount),
        (#"{"id":8,"username":"storeadmin","email":"storeadmin","roles":["administrator"]}"#, .differentAccount),
        (#"{"roles":["administrator"]}"#, .differentAccount),
        (#"{"id":7,"roles":["subscriber"]}"#, .notEligible),
        (#"{"id":7}"#, .failed),
    ])
    func test_siteIdentity_when_site_returns_a_user_then_matches_user_ID_and_eligibility(
        payload: String, expected: POSPINRecoveryIdentity
    ) {
        // Given
        let data = Data(payload.utf8)

        // When
        let result = POSPINRecoveryIdentity.siteIdentity(statusCode: 200, data: data, expectedUserID: 7)

        // Then
        #expect(result == expected)
    }

    @Test(arguments: [(403, POSPINRecoveryIdentity.notEligible), (401, .failed), (500, .failed)])
    func test_siteIdentity_when_wordpress_com_returns_an_error_then_rejects(status: Int, expected: POSPINRecoveryIdentity) {
        // Given
        let data = Data(#"{"roles":["administrator"]}"#.utf8)

        // When
        let result = POSPINRecoveryIdentity.siteIdentity(statusCode: status, data: data)

        // Then
        #expect(result == expected)
    }

    @Test(arguments: ["recovery", "unknown", "invalid"])
    func test_applicationPasswordUUID_when_list_contains_several_credentials_then_selects_only_valid_match(appID: String) {
        // Given
        let data = Data("""
        [
            {"uuid":"11111111-1111-1111-1111-111111111111","app_id":"app"},
            {"uuid":"22222222-2222-2222-2222-222222222222","app_id":"recovery"},
            {"uuid":"invalid-uuid","app_id":"invalid"}
        ]
        """.utf8)

        // When
        let uuid = POSPINRecoveryIdentity.applicationPasswordUUID(in: data, appID: appID)

        // Then
        #expect(uuid == (appID == "recovery" ? "22222222-2222-2222-2222-222222222222" : nil))
    }
}
