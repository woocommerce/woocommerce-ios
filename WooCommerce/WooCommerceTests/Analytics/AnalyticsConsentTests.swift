import Foundation
import Testing
@testable import WooCommerce

struct AnalyticsConsentTests {
    @Test(arguments: [true, false])
    func test_consent_when_UI_testing_then_disables_tracking_without_changing_saved_preference(optedIn: Bool) {
        // Given
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let consent = UserDefaultsAnalyticsConsent(userDefaults: defaults, isUITesting: true)

        // When
        consent.userHasOptedIn = optedIn

        // Then
        #expect(!consent.userHasOptedIn)
        let savedConsent = UserDefaultsAnalyticsConsent(userDefaults: defaults, isUITesting: false)
        #expect(savedConsent.userHasOptedIn == optedIn)
    }
}
