import Foundation
import Networking
import WordPressKit
import Storage
import XCTest
@testable import Yosemite

/// Mock for `AnnouncementsRemote`.
///
final class MockAnnouncementsRemote {

    /// The results to pass to the `completion` block if `getAnnouncement()` is called.
    private var loadAnnouncementResults = [String: Result<[WordPressKit.Announcement], Error>]()

    /// The amount of times that the `getAnnouncement` was invoked
    var numberOfTimesGetAnnouncementWasCalled = 0

    /// The requested appId. WooCommerce appID can be found here:
    /// https://fieldguide.automattic.com/mobile-feature-announcements/mobile-feature-announcement-endpoint/
    var requestedAppId = ""

    func whenLoadingAnnouncements(for appVersion: String, thenReturn result: Result<[WordPressKit.Announcement], Error>) {
        loadAnnouncementResults[appVersion] = result
    }
}

// MARK: AnnouncementsRemoteProtocol

extension MockAnnouncementsRemote: AnnouncementsRemoteProtocol {

    func getAnnouncements(appId: String,
                          appVersion: String,
                          locale: String,
                          completion: @escaping (Result<[WordPressKit.Announcement], Error>) -> Void) {
        numberOfTimesGetAnnouncementWasCalled += 1
        requestedAppId = appId
        if let result = self.loadAnnouncementResults[appVersion] {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Announcement for \(appVersion)")
        }
    }
}
