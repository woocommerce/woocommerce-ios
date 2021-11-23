import Combine
import Foundation
import Networking

import XCTest

/// Mock for `MediaRemote`.
///
final class MockMediaRemote {
    /// Returns the value as a publisher when `loadSites` is called.
    var loadSitesResult: Result<[Site], Error> = .success([])

    /// Returns the requests that have been made to `MediaRemoteProtocol`.
    var invocations = [Invocation]()

    /// The results to return based on the given site ID in `loadMediaLibrary`
    private var loadMediaLibraryResultsBySiteID = [Int64: Result<[Media], Error>]()

    /// The results to return based on the given site ID in `loadMediaLibraryFromWordPressSite`
    private var loadMediaLibraryFromWordPressSiteResultsBySiteID = [Int64: Result<[WordPressMedia], Error>]()

    /// The results to return based on the given site ID in `uploadMedia`
    private var uploadMediaResultsBySiteID = [Int64: Result<[Media], Error>]()

    /// The results to return based on the given site ID in `uploadMediaToWordPressSite`
    private var uploadMediaToWordPressSiteResultsBySiteID = [Int64: Result<WordPressMedia, Error>]()

    /// Returns the value as a publisher when `loadMediaLibrary` is called.
    func whenLoadingMediaLibrary(siteID: Int64, thenReturn result: Result<[Media], Error>) {
        loadMediaLibraryResultsBySiteID[siteID] = result
    }

    /// Returns the value as a publisher when `loadMediaLibraryFromWordPressSite` is called.
    func whenLoadingMediaLibraryFromWordPressSite(siteID: Int64, thenReturn result: Result<[WordPressMedia], Error>) {
        loadMediaLibraryFromWordPressSiteResultsBySiteID[siteID] = result
    }

    /// Returns the value as a publisher when `uploadMedia` is called.
    func whenUploadingMedia(siteID: Int64, thenReturn result: Result<[Media], Error>) {
        uploadMediaResultsBySiteID[siteID] = result
    }

    /// Returns the value as a publisher when `uploadMediaToWordPressSite` is called.
    func whenUploadingMediaToWordPressSite(siteID: Int64, thenReturn result: Result<WordPressMedia, Error>) {
        uploadMediaToWordPressSiteResultsBySiteID[siteID] = result
    }
}

extension MockMediaRemote {
    enum Invocation: Equatable {
        case loadMediaLibrary(siteID: Int64)
        case loadMediaLibraryFromWordPressSite(siteID: Int64)
        case uploadMedia(siteID: Int64)
        case uploadMediaToWordPressSite(siteID: Int64)
    }
}

// MARK: - AccountRemoteProtocol

extension MockMediaRemote: MediaRemoteProtocol {
    func loadMediaLibrary(for siteID: Int64, pageNumber: Int, pageSize: Int, context: String?, completion: @escaping (Result<[Media], Error>) -> Void) {
        invocations.append(.loadMediaLibrary(siteID: siteID))
        guard let result = loadMediaLibraryResultsBySiteID[siteID] else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }

    func loadMediaLibraryFromWordPressSite(siteID: Int64, pageNumber: Int, pageSize: Int, completion: @escaping (Result<[WordPressMedia], Error>) -> Void) {
        invocations.append(.loadMediaLibraryFromWordPressSite(siteID: siteID))
        guard let result = loadMediaLibraryFromWordPressSiteResultsBySiteID[siteID] else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }

    func uploadMedia(for siteID: Int64,
                     productID: Int64,
                     context: String?,
                     mediaItems: [UploadableMedia],
                     completion: @escaping (Result<[Media], Error>) -> Void) {
        invocations.append(.uploadMedia(siteID: siteID))
        guard let result = uploadMediaResultsBySiteID[siteID] else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }

    func uploadMediaToWordPressSite(siteID: Int64,
                                    productID: Int64,
                                    mediaItems: [UploadableMedia],
                                    completion: @escaping (Result<WordPressMedia, Error>) -> Void) {
        invocations.append(.uploadMediaToWordPressSite(siteID: siteID))
        guard let result = uploadMediaToWordPressSiteResultsBySiteID[siteID] else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }
}
