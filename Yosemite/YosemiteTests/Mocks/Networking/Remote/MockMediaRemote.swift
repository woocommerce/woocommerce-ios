import Foundation
import Networking

import XCTest

/// Mock for `MediaRemote`.
///
final class MockMediaRemote {
    /// Returns the requests that have been made to `MediaRemoteProtocol`.
    var invocations = [Invocation]()

    /// The results to return based on the given site ID in `loadMedia`
    private var loadMediaResultsBySiteID = [Int64: Result<WordPressMedia, Error>]()

    /// The results to return based on the given site ID in `loadMediaLibrary`
    private var loadMediaLibraryResultsBySiteID = [Int64: Result<[WordPressMedia], Error>]()

    /// The results to return based on the given site ID in `uploadMedia`
    private var uploadMediaResultsBySiteID = [Int64: Result<WordPressMedia, Error>]()

    /// The results to return based on the given site ID in `updateProductID`
    private var updateProductIDResultsBySiteID = [Int64: Result<Media, Error>]()

    /// The results to return based on the given site ID in `updateProductIDToWordPressSite`
    private var updateProductIDToWordPressSiteResultsBySiteID = [Int64: Result<WordPressMedia, Error>]()

    /// Returns the value as a publisher when `loadMedia` is called.
    func whenLoadingMedia(siteID: Int64, thenReturn result: Result<WordPressMedia, Error>) {
        loadMediaResultsBySiteID[siteID] = result
    }

    /// Returns the value as a publisher when `loadMediaLibrary` is called.
    func whenLoadingMediaLibrary(siteID: Int64, thenReturn result: Result<[WordPressMedia], Error>) {
        loadMediaLibraryResultsBySiteID[siteID] = result
    }

    /// Returns the value as a publisher when `uploadMedia` is called.
    func whenUploadingMedia(siteID: Int64, thenReturn result: Result<WordPressMedia, Error>) {
        uploadMediaResultsBySiteID[siteID] = result
    }

    /// Returns the value as a publisher when `updateProductID` is called.
    func whenUpdatingProductID(siteID: Int64, thenReturn result: Result<Media, Error>) {
        updateProductIDResultsBySiteID[siteID] = result
    }

    /// Returns the value as a publisher when `updateProductIDToWordPressSite` is called.
    func whenUpdatingProductIDToWordPressSite(siteID: Int64, thenReturn result: Result<WordPressMedia, Error>) {
        updateProductIDToWordPressSiteResultsBySiteID[siteID] = result
    }
}

extension MockMediaRemote {
    enum Invocation: Equatable {
        case loadMedia(siteID: Int64, mediaID: Int64)
        case loadMediaLibrary(siteID: Int64)
        case uploadMedia(siteID: Int64)
        case updateProductID(siteID: Int64)
        case updateProductIDToWordPressSite(siteID: Int64)
    }
}

// MARK: - MediaRemoteProtocol

extension MockMediaRemote: MediaRemoteProtocol {
    func loadMedia(siteID: Int64, mediaID: Int64, completion: @escaping (Result<Networking.WordPressMedia, Error>) -> Void) {
        invocations.append(.loadMedia(siteID: siteID, mediaID: mediaID))
        guard let result = loadMediaResultsBySiteID[siteID] else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }

    func loadMediaLibrary(siteID: Int64,
                          productID: Int64?,
                          imagesOnly: Bool,
                          pageNumber: Int,
                          pageSize: Int,
                          completion: @escaping (Result<[WordPressMedia], Error>) -> Void) {
        invocations.append(.loadMediaLibrary(siteID: siteID))
        guard let result = loadMediaLibraryResultsBySiteID[siteID] else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }

    func uploadMedia(siteID: Int64,
                     productID: Int64,
                     mediaItem: UploadableMedia,
                     completion: @escaping (Result<WordPressMedia, Error>) -> Void) {
        invocations.append(.uploadMedia(siteID: siteID))
        guard let result = uploadMediaResultsBySiteID[siteID] else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }

    func updateProductID(siteID: Int64,
                         productID: Int64,
                         mediaID: Int64,
                         completion: @escaping (Result<Media, Error>) -> Void) {
        invocations.append(.updateProductID(siteID: siteID))
        guard let result = updateProductIDResultsBySiteID[siteID] else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }

    func updateProductIDToWordPressSite(siteID: Int64,
                                        productID: Int64,
                                        mediaID: Int64,
                                        completion: @escaping (Result<WordPressMedia, Error>) -> Void) {
        invocations.append(.updateProductIDToWordPressSite(siteID: siteID))
        guard let result = updateProductIDToWordPressSiteResultsBySiteID[siteID] else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }
}
