import Testing

@testable import Yosemite

struct ApplicationPasswordSiteMatcherTests {
    // MARK: - `isWithinSite(siteURL:candidateURL:)`

    @Test(arguments: [
        (Constants.siteURL, Constants.siteURL), // same URL
        (Constants.siteURL, "http://site.example"), // different scheme
        (Constants.siteURL, "https://site.example:8443"), // port
        (Constants.siteURL, "https://site.example/wp/wp-admin/authorize-application.php?app_name=woo"), // path
        (Constants.siteURL, "https://www.site.example"), // candidate has a www prefix
        ("https://www.site.example", Constants.siteURL), // site address has a www prefix
        (Constants.siteURL, "https://WWW.Site.EXAMPLE"), // uppercase host
        ("site.example", Constants.siteURL), // site address has no scheme
        ("  https://site.example  ", Constants.siteURL), // site address has surrounding whitespace
        ("https://network.example/shop/", "https://network.example/Shop/wp-admin/authorize-application.php") // below the site path
    ])
    func test_isWithinSite_when_candidate_is_within_the_site_then_returns_true(siteURL: String, candidateURL: String) {
        // Given
        // siteURL and candidateURL from the arguments

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(result)
    }

    @Test(arguments: [
        (Constants.siteURL, "https://other.example"), // another host
        (Constants.siteURL, "https://site.example.evil.test"), // lookalike host
        (Constants.siteURL, "https://shop.site.example"), // subdomain
        (Constants.siteURL, "https://www.www.site.example"), // doubled www prefix
        (Constants.siteURL, nil), // nil candidate
        (Constants.siteURL, "   "), // blank candidate
        ("", Constants.siteURL), // blank site address
        (Constants.siteURL, "ftp://site.example"), // non-http scheme
        (Constants.siteURL, "https://merchant@site.example"), // user name in URL
        (Constants.siteURL, "https://merchant:secret@site.example"), // user name and password in URL
        (Constants.siteURL, "https://site.example@other.example"), // user info hides another host
        (Constants.siteURL, "https://"), // unparseable
        (Constants.siteURL, "https://site example"), // invalid host
        ("https://network.example/shop", "https://network.example/evil"), // sibling site on the same host
        ("https://network.example/shop", "https://network.example"), // parent of the site path
        ("https://network.example/shop", "https://network.example/shopper"), // path only shares a prefix
        ("https://network.example/evil", "https://network.example/evil%2F..%2Fshop/wp-admin/authorize-application.php"), // encoded dot segments
        ("https://network.example/evil", "https://network.example/evil%5C..%5Cshop/wp-admin/authorize-application.php") // backslash
    ] as [(String, String?)])
    func test_isWithinSite_when_candidate_is_outside_the_site_then_returns_false(siteURL: String, candidateURL: String?) {
        // Given
        // siteURL and candidateURL from the arguments

        // When
        let result = ApplicationPasswordSiteMatcher.isWithinSite(siteURL: siteURL, candidateURL: candidateURL)

        // Then
        #expect(!result)
    }

    // MARK: - `approvalSiteURL(for:)`

    @Test(arguments: [
        ("https://wp.site.example/wp-admin/authorize-application.php?app_name=woo&success_url=woocommerce://login",
         "https://wp.site.example"), // approval page at the site root
        ("https://site.example/wp/wp-admin/authorize-application.php", "https://site.example/wp"), // subfolder install
        ("https://site.example/private-admin/authorize-application.php", Constants.siteURL), // renamed admin directory
        ("https://site.example/wp-admin/authorize-application.php/x/y", Constants.siteURL), // extra path after the approval page
        ("https://site.example/shop/wp-admin%2Fauthorize-application.php", "https://site.example/shop") // encoded slash before the approval page
    ])
    func test_approvalSiteURL_when_URL_is_an_approval_page_then_returns_the_site_address(authorizationURL: String, expectedSiteURL: String) {
        // Given
        // authorizationURL and expectedSiteURL from the arguments

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == expectedSiteURL)
    }

    @Test(arguments: [
        "https://site.example/ea-authorize/", // not the approval page
        "https://x@site.example/wp-admin/authorize-application.php", // user name in URL
        "https://site.example/authorize-application.php", // no admin directory
        nil // nil URL
    ] as [String?])
    func test_approvalSiteURL_when_URL_is_not_a_usable_approval_page_then_returns_nil(authorizationURL: String?) {
        // Given
        // authorizationURL from the arguments

        // When
        let result = ApplicationPasswordSiteMatcher.approvalSiteURL(for: authorizationURL)

        // Then
        #expect(result == nil)
    }

    // MARK: - `isSameSiteAddress(_:_:)`

    @Test(arguments: [
        ("https://site.example/shop", "http://www.site.example/shop/", true), // differs by trailing slash and www
        (Constants.siteURL, "https://site.example/wp", false) // candidate has a deeper path
    ])
    func test_isSameSiteAddress_when_addresses_are_compared_then_returns_whether_they_match(siteURL: String,
                                                                                            candidateURL: String,
                                                                                            expected: Bool) {
        // Given
        // siteURL, candidateURL and expected from the arguments

        // When
        let result = ApplicationPasswordSiteMatcher.isSameSiteAddress(siteURL, candidateURL)

        // Then
        #expect(result == expected)
    }

    // MARK: - `isApprovalPage(_:)`

    @Test(arguments: [
        "https://site.example/wp-admin/authorize-application.php/x", // extra path after the approval page
        "https://site.example/wp-admin/authorize-application%2Ephp", // encoded approval page name
        "https://x@site.example/wp-admin/authorize-application.php", // user name in URL
        "https://x:y@site.example/wp-admin/authorize-application.php", // user name and password in URL
        "https://site.example/wp-admin%2Fauthorize-application.php", // encoded slash before the approval page
        "https://site.example/wp-admin/authorize-application.php%2Fx", // encoded slash after the approval page
        "https://site.example/wp-admin/authorize-application.php%2F..%2Fx" // dot segments after the approval page
    ])
    func test_isApprovalPage_when_URL_points_to_the_approval_page_then_returns_true(url: String) {
        // Given
        // url from the arguments

        // When
        let result = ApplicationPasswordSiteMatcher.isApprovalPage(url)

        // Then
        #expect(result)
    }

    @Test(arguments: [
        "https://site.example/wp-login.php?redirect_to=x" // login page
    ])
    func test_isApprovalPage_when_URL_is_another_page_then_returns_false(url: String) {
        // Given
        // url from the arguments

        // When
        let result = ApplicationPasswordSiteMatcher.isApprovalPage(url)

        // Then
        #expect(!result)
    }
}

private extension ApplicationPasswordSiteMatcherTests {
    enum Constants {
        static let siteURL = "https://site.example"
    }
}
