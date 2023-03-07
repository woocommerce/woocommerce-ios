import XCTest
@testable import Networking

final class AnnouncementListMapperTests: XCTestCase {
    /// Verifies that all of the Announcement fields are properly parsed.
    ///
    func test_announcements_are_properly_parsed() {
        let announcements = mapLoadAnnouncementListResponse()

        assertEqual(2, announcements.count)
        let firstItem = announcements[0]
        assertEqual("10.7", firstItem.appVersionName)
        assertEqual("10.7", firstItem.minimumAppVersion)
        assertEqual("10.7", firstItem.maximumAppVersion)
        assertEqual(0, firstItem.appVersionTargets.count)
        assertEqual("http://wordpress.org", firstItem.detailsUrl)
        assertEqual(2, firstItem.features.count)
        assertEqual("246", firstItem.announcementVersion)
        assertEqual("en", firstItem.responseLocale)
        XCTAssertTrue(firstItem.isLocalized)
        let firstFeature = firstItem.features[0]
        assertEqual("Reply to Product Reviews", firstFeature.title)
        assertEqual("Want to show customers that you're listening to their feedback? Use the new Reply button to respond to product reviews that need your attention.", firstFeature.subtitle)
        assertEqual("https://example.com/", firstFeature.iconUrl)
        assertEqual("https://example.com/", firstFeature.icons?.first?.iconUrl)
    }
}

private extension AnnouncementListMapperTests {
    func mapLoadAnnouncementListResponse() -> [Announcement] {
        guard let response = Loader.contentsOf("announcements") else {
            return []
        }

        return (try? AnnouncementListMapper().map(response: response)) ?? []
    }
}
