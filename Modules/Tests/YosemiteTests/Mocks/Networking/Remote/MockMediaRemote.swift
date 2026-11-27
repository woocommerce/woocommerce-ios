import Foundation
import Networking
import Synchronization

import XCTest

/// Mock for `MediaRemote`.
///
final class MockMediaRemote {
    private struct State {
        var invocations: [Invocation] = []
        var loadMediaResultsBySiteID: [Int64: Result<WordPressMedia, Error>] = [:]
        var loadMediaLibraryResultsBySiteID: [Int64: Result<[WordPressMedia], Error>] = [:]
        var uploadMediaResultsBySiteID: [Int64: Result<WordPressMedia, Error>] = [:]
        var updateProductIDResultsBySiteID: [Int64: Result<WordPressMedia, Error>] = [:]
    }

    private let state = Mutex(State())

    var invocations: [Invocation] {
        state.withLock { $0.invocations }
    }

    /// Returns the value as a publisher when `loadMedia` is called.
    func whenLoadingMedia(siteID: Int64, thenReturn result: Result<WordPressMedia, Error>) {
        state.withLock { $0.loadMediaResultsBySiteID[siteID] = result }
    }

    /// Returns the value as a publisher when `loadMediaLibrary` is called.
    func whenLoadingMediaLibrary(siteID: Int64, thenReturn result: Result<[WordPressMedia], Error>) {
        state.withLock { $0.loadMediaLibraryResultsBySiteID[siteID] = result }
    }

    /// Returns the value as a publisher when `uploadMedia` is called.
    func whenUploadingMedia(siteID: Int64, thenReturn result: Result<WordPressMedia, Error>) {
        state.withLock { $0.uploadMediaResultsBySiteID[siteID] = result }
    }

    /// Returns the value as a publisher when `updateProductID` is called.
    func whenUpdatingProductID(siteID: Int64, thenReturn result: Result<WordPressMedia, Error>) {
        state.withLock { $0.updateProductIDResultsBySiteID[siteID] = result }
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
        let result = state.withLock { state in
            state.invocations.append(.loadMedia(siteID: siteID, mediaID: mediaID))
            return state.loadMediaResultsBySiteID[siteID]
        }
        guard let result else {
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
        let result = state.withLock { state in
            state.invocations.append(.loadMediaLibrary(siteID: siteID))
            return state.loadMediaLibraryResultsBySiteID[siteID]
        }
        guard let result else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }

    func uploadMedia(siteID: Int64,
                     productID: Int64,
                     mediaItem: UploadableMedia,
                     completion: @escaping (Result<WordPressMedia, Error>) -> Void) {
        let result = state.withLock { state in
            state.invocations.append(.uploadMedia(siteID: siteID))
            return state.uploadMediaResultsBySiteID[siteID]
        }
        guard let result else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }

    func updateProductID(siteID: Int64,
                         productID: Int64,
                         mediaID: Int64,
                         completion: @escaping (Result<WordPressMedia, Error>) -> Void) {
        let result = state.withLock { state in
            state.invocations.append(.updateProductID(siteID: siteID))
            return state.updateProductIDResultsBySiteID[siteID]
        }
        guard let result else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return
        }
        completion(result)
    }
}
