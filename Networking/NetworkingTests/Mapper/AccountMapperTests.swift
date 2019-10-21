import XCTest

@testable import Networking

/// AccountMapper Unit Tests
///
class AccountMapperTests: XCTestCase {

    /// Verifies that all of the Account fields are properly parsed.
    ///
    func testAccountFieldsArePropertlyParsed() {
        guard let account = mapLoadAccountResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(account.displayName, "apiexamples")
        XCTAssertEqual(account.email, "example@example.blog")
        XCTAssertEqual(account.gravatarUrl, "https://1.gravatar.com/avatar/a2afb7b6c0e23e5d363d8612fb1bd5ad?s=96&d=identicon&r=G")
        XCTAssertEqual(account.userID, 78_972_699)
        XCTAssertEqual(account.username, "apiexamples")
    }

    /// Verifies that all of the Site fields are properly parsed.
    ///
    func testSiteFieldsAreProperlyParsed() {
        let sites = mapLoadSitesResponse()
        XCTAssert(sites?.count == 2)

        let first = sites!.first!
        XCTAssertEqual(first.siteID, 1_112_233_334_444_555)
        XCTAssertEqual(first.name, "Testing Blog")
        XCTAssertEqual(first.description, "Testing Tagline")
        XCTAssertEqual(first.url, "https://some-testing-url.testing.blog")
        XCTAssertEqual(first.isWooCommerceActive, true)
        XCTAssertEqual(first.isWordPressStore, true)

        let second = sites!.last!
        XCTAssertEqual(second.siteID, 11_122_333_344_446_666)
        XCTAssertEqual(second.name, "Thoughts")
        XCTAssertEqual(second.description, "Your Favorite Blog")
        XCTAssertEqual(second.url, "https://thoughts.testing.blog")
        XCTAssertEqual(second.isWooCommerceActive, false)
        XCTAssertEqual(second.isWordPressStore, false)
    }

    /// Verifies that the Plan field for Site is properly parsed.
    ///
    func testSitePlanFieldIsProperlyParsed() {
        let site = mapLoadSitePlanResponse()

        XCTAssertEqual(site!.siteID, 1_112_233_334_444_555)
        XCTAssertEqual(site!.shortName, "Business")
    }
}


// MARK: - Private Methods.
//
extension AccountMapperTests {

    /// Returns the AccountMapper output upon receiving `me` mockup response (Data Encoded).
    ///
    fileprivate func mapLoadAccountResponse() -> Account? {
        guard let response = Loader.contentsOf("me") else {
            return nil
        }

        return try? AccountMapper().map(response: response)
    }

    /// Returns the SiteListMapper output upon receiving `me/sites` mockup response (Data Encoded).
    ///
    fileprivate func mapLoadSitesResponse() -> [Site]? {
        guard let response = Loader.contentsOf("sites") else {
            return nil
        }

        return try? SiteListMapper().map(response: response)
    }

    /// Returns the SitePlanMapper output upon receiving `sites/$site` mockup response (Data Encoded).
    ///
    fileprivate func mapLoadSitePlanResponse() -> SitePlan? {
        guard let response = Loader.contentsOf("site-plan") else {
            return nil
        }

        return try? SitePlanMapper().map(response: response)
    }
}
