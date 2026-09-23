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
}
