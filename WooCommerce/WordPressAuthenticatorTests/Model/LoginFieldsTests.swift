@testable import WordPressAuthenticator
import XCTest

class LoginFieldsTests: XCTestCase {

    func testSignInWithAppleParametersNilWhenNoSocialUser() {
        XCTAssertNil(LoginFields().parametersForSignInWithApple)
    }

    func testSignInWithAppleParametersNilWhenSocialUserNotApple() {
        let fields = LoginFields()
        fields.meta = LoginFieldsMeta(
            socialUser: SocialUser(email: "email", fullName: "name", service: .google)
        )

        XCTAssertNil(fields.parametersForSignInWithApple)
    }

    func testSignInWithAppleParametersHasEmailAndNameWhenSocialUserIsApple() throws {
        let fields = LoginFields()
        fields.meta = LoginFieldsMeta(
            socialUser: SocialUser(email: "email", fullName: "name", service: .apple)
        )

        let parameters = try XCTUnwrap(fields.parametersForSignInWithApple)
        XCTAssertEqual(parameters["user_email"] as? String, "email")
        XCTAssertEqual(parameters["user_name"] as? String, "name")
    }

    // MARK: - effectiveSiteAddress

    func testEffectiveSiteAddressIsTheSiteAddressWhenNothingIsStashed() {
        let loginFields = LoginFields()
        loginFields.siteAddress = "https://example.com"

        XCTAssertEqual(loginFields.effectiveSiteAddress, "https://example.com")
    }

    func testEffectiveSiteAddressIsTheStashedAddressWhileTheSiteAddressHoldsTheMarker() {
        let loginFields = LoginFields()
        loginFields.siteAddressForEpilogue = "https://example.com"
        loginFields.siteAddress = LoginFields.wpComSiteAddress

        XCTAssertEqual(loginFields.effectiveSiteAddress, "https://example.com")
    }

    func testEffectiveSiteAddressPrefersANewlyEnteredAddressOverTheStash() {
        let loginFields = LoginFields()
        loginFields.siteAddressForEpilogue = "https://first.example.com"
        loginFields.siteAddress = LoginFields.wpComSiteAddress

        // The merchant goes back and enters a different store.
        loginFields.siteAddress = "https://second.example.com"

        XCTAssertEqual(loginFields.effectiveSiteAddress, "https://second.example.com")
    }

    func testEffectiveSiteAddressIsTheMarkerWhenNoAddressWasEntered() {
        let loginFields = LoginFields()
        loginFields.siteAddress = LoginFields.wpComSiteAddress

        XCTAssertEqual(loginFields.effectiveSiteAddress, LoginFields.wpComSiteAddress)
    }

    func testCopyCarriesTheStashedAddress() {
        let loginFields = LoginFields()
        loginFields.siteAddress = LoginFields.wpComSiteAddress
        loginFields.siteAddressForEpilogue = "https://example.com"

        let copiedFields: LoginFields = loginFields.copy()

        XCTAssertEqual(copiedFields.siteAddressForEpilogue, "https://example.com")
        XCTAssertEqual(copiedFields.effectiveSiteAddress, "https://example.com")
    }

    // MARK: - restoreSiteAddressAfterWPComFallback

    func testRestoringAfterTheFallbackPutsTheStashedAddressBackAndClearsTheStash() {
        // Given the fallback replaced the typed address with the marker
        let loginFields = LoginFields()
        loginFields.siteAddressForEpilogue = "https://example.com"
        loginFields.siteAddress = LoginFields.wpComSiteAddress

        // When the fallback screen is left
        loginFields.restoreSiteAddressAfterWPComFallback()

        // Then the screens behind it see the typed address again
        XCTAssertEqual(loginFields.siteAddress, "https://example.com")
        XCTAssertEqual(loginFields.siteAddressForEpilogue, "")
    }

    func testRestoringDoesNothingWhenTheFallbackWasNeverTaken() {
        // Given a WP.com login that never stashed an address
        let loginFields = LoginFields()
        loginFields.siteAddress = LoginFields.wpComSiteAddress

        // When
        loginFields.restoreSiteAddressAfterWPComFallback()

        // Then
        XCTAssertEqual(loginFields.siteAddress, LoginFields.wpComSiteAddress)
    }

    func testRestoringLeavesANewlyEnteredAddressAlone() {
        // Given the merchant went back and entered a different store before this ran
        let loginFields = LoginFields()
        loginFields.siteAddressForEpilogue = "https://first.example.com"
        loginFields.siteAddress = "https://second.example.com"

        // When
        loginFields.restoreSiteAddressAfterWPComFallback()

        // Then the address last asked for wins
        XCTAssertEqual(loginFields.siteAddress, "https://second.example.com")
    }
}
