
import Foundation
import Networking
import Storage
import XCTest
@testable import Yosemite

/// Mock for `AnnouncementsRemote`.
///
final class MockAnnouncementsRemote {

    private typealias AppVersion = String

    /// The results to pass to the `completion` block if `getFeatures()` is called.
    private var loadFeaturesResults = [AppVersion: Result<[WooCommerceFeature], Error>]()

    /// The amount of times that the `getFeatures` was invoked
    var numberOfTimesGetFeaturesWasCalled = 0

    /// The requested appId. WooCommerce appID can be found here:
    /// https://fieldguide.automattic.com/mobile-feature-announcements/mobile-feature-announcement-endpoint/
    var requestedAppId = ""

    func whenLoadingFeatures(for appVersion: String, thenReturn result: Result<[WooCommerceFeature], Error>) {
        loadFeaturesResults[appVersion] = result
    }
}

// MARK: AnnouncementsRemoteProtocol

extension MockAnnouncementsRemote: AnnouncementsRemoteProtocol {

    func getFeatures(appId: String,
                     appVersion: String,
                     locale: String,
                     completion: @escaping (Result<[WooCommerceFeature], Error>) -> Void) {
        numberOfTimesGetFeaturesWasCalled += 1
        requestedAppId = appId
        if let result = self.loadFeaturesResults[appVersion] {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Features for \(appVersion)")
        }
    }
}
