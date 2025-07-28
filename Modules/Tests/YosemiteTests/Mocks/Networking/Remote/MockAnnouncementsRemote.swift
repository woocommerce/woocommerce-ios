import Foundation
import Networking
import XCTest
@testable import Yosemite

/// Mock for `AnnouncementsRemote`.
///
final class MockAnnouncementsRemote {

    /// The results to pass to the `completion` block if `loadAnnouncements()` is called.
    private var loadAnnouncementResults = [String: Result<[Announcement], Error>]()

    /// The amount of times that the `getAnnouncement` was invoked
    var numberOfTimesGetAnnouncementWasCalled = 0

    func whenLoadingAnnouncements(for appVersion: String, thenReturn result: Result<[Announcement], Error>) {
        loadAnnouncementResults[appVersion] = result
    }
}

// MARK: AnnouncementsRemoteProtocol

extension MockAnnouncementsRemote: AnnouncementsRemoteProtocol {

    func loadAnnouncements(appVersion: String,
                           locale: String,
                           onCompletion: @escaping (Result<[Announcement], Error>) -> Void) {
        numberOfTimesGetAnnouncementWasCalled += 1
        if let result = self.loadAnnouncementResults[appVersion] {
            onCompletion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Announcement for \(appVersion)")
        }
    }
}
