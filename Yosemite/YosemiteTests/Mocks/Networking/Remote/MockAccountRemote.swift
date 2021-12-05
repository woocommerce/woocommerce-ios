import Combine
import Foundation
import Networking

import XCTest

/// Mock for `AccountRemote`.
///
final class MockAccountRemote {
    /// Returns the value as a publisher when `loadSites` is called.
    var loadSitesResult: Result<[Site], Error> = .success([])

    /// Returns the requests that have been made to `AccountRemoteProtocol`.
    var invocations = [Invocation]()

    /// The results to return based on the given site ID in `checkIfWooCommerceIsActive`
    private var checkIfWooCommerceIsActiveResultsBySiteID = [Int64: Result<Bool, Error>]()

    /// The results to return based on the given site ID in `fetchWordPressSiteSettings`
    private var fetchWordPressSiteSettingsResultsBySiteID = [Int64: Result<WordPressSiteSettings, Error>]()

    /// Returns the value as a publisher when `checkIfWooCommerceIsActive` is called.
    func whenCheckingIfWooCommerceIsActive(siteID: Int64, thenReturn result: Result<Bool, Error>) {
        checkIfWooCommerceIsActiveResultsBySiteID[siteID] = result
    }

    /// Returns the value as a publisher when `fetchWordPressSiteSettings` is called.
    func whenFetchingWordPressSiteSettings(siteID: Int64, thenReturn result: Result<WordPressSiteSettings, Error>) {
        fetchWordPressSiteSettingsResultsBySiteID[siteID] = result
    }
}

extension MockAccountRemote {
    enum Invocation: Equatable {
        case loadSites
        case checkIfWooCommerceIsActive(siteID: Int64)
        case fetchWordPressSiteSettings(siteID: Int64)
    }
}

// MARK: - AccountRemoteProtocol

extension MockAccountRemote: AccountRemoteProtocol {
    func loadAccount(completion: @escaping (Result<Account, Error>) -> Void) {
        // no-op
    }

    func loadAccountSettings(for userID: Int64, completion: @escaping (Result<AccountSettings, Error>) -> Void) {
        // no-op
    }

    func updateAccountSettings(for userID: Int64, tracksOptOut: Bool, completion: @escaping (Result<AccountSettings, Error>) -> Void) {
        // no-op
    }

    func loadSites() -> AnyPublisher<Result<[Site], Error>, Never> {
        invocations.append(.loadSites)
        return Just<Result<[Site], Error>>(loadSitesResult).eraseToAnyPublisher()
    }

    func checkIfWooCommerceIsActive(for siteID: Int64) -> AnyPublisher<Result<Bool, Error>, Never> {
        invocations.append(.checkIfWooCommerceIsActive(siteID: siteID))
        if let result = checkIfWooCommerceIsActiveResultsBySiteID[siteID] {
            return Just<Result<Bool, Error>>(result).eraseToAnyPublisher()
        } else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return Empty<Result<Bool, Error>, Never>().eraseToAnyPublisher()
        }
    }

    func fetchWordPressSiteSettings(for siteID: Int64) -> AnyPublisher<Result<WordPressSiteSettings, Error>, Never> {
        invocations.append(.fetchWordPressSiteSettings(siteID: siteID))
        if let result = fetchWordPressSiteSettingsResultsBySiteID[siteID] {
            return Just<Result<WordPressSiteSettings, Error>>(result).eraseToAnyPublisher()
        } else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return Empty<Result<WordPressSiteSettings, Error>, Never>().eraseToAnyPublisher()
        }
    }

    func loadSitePlan(for siteID: Int64, completion: @escaping (Result<SitePlan, Error>) -> Void) {
        // no-op
    }
}
