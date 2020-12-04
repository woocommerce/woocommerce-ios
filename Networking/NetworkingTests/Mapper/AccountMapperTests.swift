import XCTest
@testable import Networking


/// AccountMapper Unit Tests
///
class AccountMapperTests: XCTestCase {

    /// Verifies that all of the Account fields are properly parsed.
    ///
    func test_Account_fields_are_properly_parsed() {
        guard let account = mapLoadAccountResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(account.displayName, "apiexamples")
        XCTAssertEqual(account.email, "example@example.blog")
        XCTAssertEqual(account.gravatarUrl, "https://1.gravatar.com/avatar/a2afb7b6c0e23e5d363d8612fb1bd5ad?s=96&d=identicon&r=G")
        XCTAssertEqual(account.userID, 78972699)
        XCTAssertEqual(account.username, "apiexamples")
    }

    /// Verifies that all of the Site fields are properly parsed.
    ///
    func test_Site_fields_are_properly_parsed() {
        let sites = mapLoadSitesResponse()
        XCTAssert(sites?.count == 2)

        let first = sites!.first!
        XCTAssertEqual(first.siteID, 1112233334444555)
        XCTAssertEqual(first.name, "Testing Blog")
        XCTAssertEqual(first.description, "Testing Tagline")
        XCTAssertEqual(first.url, "https://some-testing-url.testing.blog")
        XCTAssertEqual(first.isWooCommerceActive, true)
        XCTAssertEqual(first.isWordPressStore, true)
        XCTAssertEqual(first.gmtOffset, 3.5)
        XCTAssertEqual(first.siteTimezone, TimeZone(secondsFromGMT: 12600))

        let second = sites!.last!
        XCTAssertEqual(second.siteID, 11122333344446666)
        XCTAssertEqual(second.name, "Thoughts")
        XCTAssertEqual(second.description, "Your Favorite Blog")
        XCTAssertEqual(second.url, "https://thoughts.testing.blog")
        XCTAssertEqual(second.isWooCommerceActive, false)
        XCTAssertEqual(second.isWordPressStore, false)
        XCTAssertEqual(second.gmtOffset, -4)
        XCTAssertEqual(second.siteTimezone, TimeZone(secondsFromGMT: -14400))
    }

    /// Verifies that the Plan field for Site is properly parsed.
    ///
    func test_SitePlan_field_is_properly_parsed() {
        let site = mapLoadSitePlanResponse()

        XCTAssertEqual(site!.siteID, 1112233334444555)
        XCTAssertEqual(site!.shortName, "Business")
    }
}



// MARK: - Private Methods.
//
private extension AccountMapperTests {

    /// Returns the AccountMapper output upon receiving `me` mock response (Data Encoded).
    ///
    func mapLoadAccountResponse() -> Account? {
        guard let response = Loader.contentsOf("me") else {
            return nil
        }

        return try? AccountMapper().map(response: response)
    }

    /// Returns the SiteListMapper output upon receiving `me/sites` mock response (Data Encoded).
    ///
    func mapLoadSitesResponse() -> [Site]? {
        guard let response = Loader.contentsOf("sites") else {
            return nil
        }

        return try? SiteListMapper().map(response: response)
    }

    /// Returns the SitePlanMapper output upon receiving `sites/$site` mock response (Data Encoded).
    ///
    func mapLoadSitePlanResponse() -> SitePlan? {
        guard let response = Loader.contentsOf("site-plan") else {
            return nil
        }

        return try? SitePlanMapper().map(response: response)
    }
}
