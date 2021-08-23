
import Foundation
import Networking
import WordPressKit
import XCTest
@testable import Yosemite

/// Mock for `AnnouncementsRemote`.
///
final class MockAnnouncementsRemote {

    private typealias AppVersion = String

    /// The results to pass to the `completion` block if `loadNotes()` is called.
    private var loadAnnouncementsResults = [AppVersion: Result<[Announcement], Error>]()

    /// The amount of times that the `getAnnouncements` was invoked
    var numberOfTimesGetAnnouncementsWasCalled = 0

    func whenLoadingAnnouncements(for appVersion: String, thenReturn result: Result<[Announcement], Error>) {
        loadAnnouncementsResults[appVersion] = result
    }
}

// MARK: NotificationsEndpointsProviding

extension MockAnnouncementsRemote: AnnouncementsRemoteProtocol {

    func getAnnouncements(appId: String,
                          appVersion: String,
                          locale: String,
                          completion: @escaping (Result<[Announcement], Error>) -> Void) {
        numberOfTimesGetAnnouncementsWasCalled += 1
        if let result = self.loadAnnouncementsResults[appVersion] {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Announcements for \(appVersion)")
        }
    }
}
