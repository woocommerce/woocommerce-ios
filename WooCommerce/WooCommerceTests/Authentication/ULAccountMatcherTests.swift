import Testing
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
struct ULAccountMatcherTests {
    @Test(arguments: [
        ("https://example.com", "https://www.example.com"),
        ("https://www.example.com", "example.com"),
        ("http://example.com/shop", "https://www.example.com/shop"),
        ("https://example.com/shop", "https://www.example.com/shop/"),
        ("https://www.example.com/shop/", "https://example.com/shop"),
        ("https://EXAMPLE.com/", "https://www.example.com")
    ])
    func test_match_when_www_differs_then_returns_account_site(stored: String, entered: String) {
        // Given
        let matcher = makeMatcher(urls: [stored])
        // When / Then
        #expect(matcher.match(originalURL: entered))
        #expect(matcher.matchedSite(originalURL: entered)?.siteID == 1)
        #expect(matcher.matchedSite(originalURL: entered)?.url == stored)
    }

    @Test(arguments: ["https://www.example.com", "https://example.com"])
    func test_match_when_both_hosts_exist_then_exact_match_takes_priority(entered: String) {
        // Given
        let alternate = entered.contains("www.") ? "https://example.com" : "https://www.example.com"
        let matcher = makeMatcher(urls: [alternate, entered])
        // When / Then
        #expect(matcher.matchedSite(originalURL: entered)?.siteID == 2)
    }

    @Test(arguments: [
        "https://www.example.com/another-shop", "https://www.example.com:8443/shop",
        "https://shop.example.com/shop", "https://example.com.evil.test/shop", "https://example.com/shop-extra"
    ])
    func test_match_when_site_is_different_then_does_not_match(entered: String) {
        // Given
        let matcher = makeMatcher(urls: ["https://example.com/shop"])
        // When / Then
        #expect(!matcher.match(originalURL: entered))
        #expect(matcher.matchedSite(originalURL: entered) == nil)
    }

    @Test
    func test_match_when_account_login_sentinel_then_allows_store_picker() {
        // Given
        let matcher = makeMatcher(urls: [])
        // When / Then
        #expect(matcher.match(originalURL: "https://wordpress.com"))
        #expect(matcher.matchedSite(originalURL: "https://wordpress.com") == nil)
    }

    @Test
    func test_match_when_fallback_is_ambiguous_then_does_not_select_arbitrary_store() {
        // Given
        let matcher = makeMatcher(urls: ["http://example.com", "https://example.com"])
        // When / Then
        #expect(!matcher.match(originalURL: "https://www.example.com"))
    }

    private func makeMatcher(urls: [String]) -> ULAccountMatcher {
        let storage = MockStorageManager()
        for (index, url) in urls.enumerated() {
            storage.insertSampleSite(readOnlySite: Site.fake().copy(siteID: Int64(index + 1), name: "Store \(index)", url: url))
        }
        let matcher = ULAccountMatcher(storageManager: storage)
        matcher.refreshStoredSites()
        return matcher
    }
}
