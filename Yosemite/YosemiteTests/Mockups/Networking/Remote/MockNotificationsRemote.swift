
import Foundation
import Networking

import XCTest

/// Mock for `NotificationsRemote`.
///
final class MockNotificationsRemote {
    private typealias ResultKey = [Int64]

    /// The results to pass to the `completion` block if `loadNotes()` is called.
    private var notesLoadingResults = [ResultKey: Result<[Note], Error>]()

    /// The number of times that `loadNotes` was invoked.
    private(set) var invocationCountOfLoadNotes: Int = 0

    func whenLoadingNotes(noteIDs: [Int64], thenReturn result: Result<[Note], Error>) {
        let key: ResultKey = noteIDs
        notesLoadingResults[key] = result
    }
}

// MARK: NotificationsEndpointsProviding

extension MockNotificationsRemote: NotificationsEndpointsProviding {

    func loadNotes(noteIDs: [Int64]?, pageSize: Int?, completion: @escaping (Result<[Note], Error>) -> Void) {
        guard let noteIDs = noteIDs else {
            return XCTFail("Expected noteIDs to not be nil.")
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.invocationCountOfLoadNotes += 1

            let key: ResultKey = noteIDs
            if let result = self.notesLoadingResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }
}
