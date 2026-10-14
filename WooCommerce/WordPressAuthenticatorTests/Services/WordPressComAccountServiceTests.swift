import Foundation
import Testing
@testable import WordPressAuthenticator

struct WordPressComAccountServiceTests {
    @Test func test_unknown_service_error_has_a_user_friendly_description() {
        // Given
        let error = WordPressComAccountService.ServiceError.unknown

        // When
        let description = error.localizedDescription

        // Then
        #expect(description == "Something went wrong. Please try again.")
    }
}
