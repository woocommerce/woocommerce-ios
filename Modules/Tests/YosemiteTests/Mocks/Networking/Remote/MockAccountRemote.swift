import Combine
import Foundation
import Networking
import Synchronization

import XCTest

/// Mock for `AccountRemote`.
///
final class MockAccountRemote: Sendable {
    private typealias SitesResult = Result<[Site], Error>

    private struct State {
        var loadSitesResult: SitesResult = .success([])
        var invocations = [Invocation]()
        var checkIfWooCommerceIsActiveResultsBySiteID = [Int64: Result<Bool, Error>]()
        var fetchWordPressSiteSettingsResultsBySiteID = [Int64: Result<WordPressSiteSettings, Error>]()
        var loadUsernameSuggestionsResult: Result<[String], Error>?
        var loadNotificationSettingsResult: Result<NotificationSettings, Error>?
        var updateNotificationSettingsResult: Result<Void, Error> = .success(())
        var createAccountResult: Result<CreateAccountResult, CreateAccountError>?
        var closeAccountResult: Result<Void, Error> = .success(())
        var updateCrashReportingOptOutResult: Result<Void, Error>?
    }

    private let state = Mutex(State())
    private let deferredSiteResponses = Mutex(PassthroughSubject<SitesResult, Never>())
    private let defersLoadSites: Bool

    init(defersLoadSites: Bool = false) {
        self.defersLoadSites = defersLoadSites
    }

    var loadSitesResult: Result<[Site], Error> {
        get { state.withLock { $0.loadSitesResult } }
        set { state.withLock { $0.loadSitesResult = newValue } }
    }

    var invocations: [Invocation] {
        state.withLock { $0.invocations }
    }

    func sendLoadSitesResult(_ result: Result<[Site], Error>) {
        deferredSiteResponses.withLock { $0 }.send(result)
    }

    /// Returns the value when `updateCrashReportingOptOut` is called.
    func whenUpdatingCrashReportingOptOut(thenReturn result: Result<Void, Error>) {
        state.withLock { $0.updateCrashReportingOptOutResult = result }
    }

    /// Returns the value as a publisher when `closeAccount` is called.
    func whenClosingAccount(thenReturn result: Result<Void, Error>) {
        state.withLock { $0.closeAccountResult = result }
    }

    /// Returns the value as a publisher when `checkIfWooCommerceIsActive` is called.
    func whenCheckingIfWooCommerceIsActive(siteID: Int64, thenReturn result: Result<Bool, Error>) {
        state.withLock { $0.checkIfWooCommerceIsActiveResultsBySiteID[siteID] = result }
    }

    /// Returns the value as a publisher when `fetchWordPressSiteSettings` is called.
    func whenFetchingWordPressSiteSettings(siteID: Int64, thenReturn result: Result<WordPressSiteSettings, Error>) {
        state.withLock { $0.fetchWordPressSiteSettingsResultsBySiteID[siteID] = result }
    }

    /// Returns the value when `loadUsernameSuggestions` is called.
    func whenLoadingUsernameSuggestions(thenReturn result: Result<[String], Error>) {
        state.withLock { $0.loadUsernameSuggestionsResult = result }
    }

    /// Returns the value when `createAccount` is called.
    func whenCreatingAccount(thenReturn result: Result<CreateAccountResult, CreateAccountError>) {
        state.withLock { $0.createAccountResult = result }
    }

    /// Returns  the value when `updateNotificationSettings` is called.
    func whenUpdatingNotificationSettings(thenReturn result: Result<Void, Error>) {
        state.withLock { $0.updateNotificationSettingsResult = result }
    }

    func whenLoadingNotificationSettings(thenReturn result: Result<NotificationSettings, Error>) {
        state.withLock { $0.loadNotificationSettingsResult = result }
    }
}

extension MockAccountRemote {
    enum Invocation: Equatable {
        case loadSites
        case checkIfWooCommerceIsActive(siteID: Int64)
        case fetchWordPressSiteSettings(siteID: Int64)
        case updateCrashReportingOptOut(optOut: Bool)
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

    func updateCrashReportingOptOut(optOut: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let result = state.withLock {
            $0.invocations.append(.updateCrashReportingOptOut(optOut: optOut))
            return $0.updateCrashReportingOptOutResult
        }
        guard let result else {
            XCTFail("Could not find result for updating the crash reporting opt out.")
            return completion(.failure(NetworkError.notFound()))
        }
        completion(result)
    }

    func loadSites() -> AnyPublisher<Result<[Site], Error>, Never> {
        let result = state.withLock {
            $0.invocations.append(.loadSites)
            return $0.loadSitesResult
        }
        if defersLoadSites {
            return deferredSiteResponses.withLock { $0.eraseToAnyPublisher() }
        }
        return Just(result).eraseToAnyPublisher()
    }

    func checkIfWooCommerceIsActive(for siteID: Int64) -> AnyPublisher<Result<Bool, Error>, Never> {
        let result = state.withLock {
            $0.invocations.append(.checkIfWooCommerceIsActive(siteID: siteID))
            return $0.checkIfWooCommerceIsActiveResultsBySiteID[siteID]
        }
        if let result {
            return Just<Result<Bool, Error>>(result).eraseToAnyPublisher()
        } else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return Empty<Result<Bool, Error>, Never>().eraseToAnyPublisher()
        }
    }

    func fetchWordPressSiteSettings(for siteID: Int64) -> AnyPublisher<Result<WordPressSiteSettings, Error>, Never> {
        let result = state.withLock {
            $0.invocations.append(.fetchWordPressSiteSettings(siteID: siteID))
            return $0.fetchWordPressSiteSettingsResultsBySiteID[siteID]
        }
        if let result {
            return Just<Result<WordPressSiteSettings, Error>>(result).eraseToAnyPublisher()
        } else {
            XCTFail("\(String(describing: self)) Could not find result for site ID: \(siteID)")
            return Empty<Result<WordPressSiteSettings, Error>, Never>().eraseToAnyPublisher()
        }
    }

    func loadSitePlan(for siteID: Int64, completion: @escaping (Result<SitePlan, Error>) -> Void) {
        // no-op
    }

    func loadUsernameSuggestions(from text: String) async throws -> [String] {
        guard let result = state.withLock({ $0.loadUsernameSuggestionsResult }) else {
            XCTFail("Could not find result for loading username suggestions.")
            throw NetworkError.notFound()
        }

        return try result.get()
    }

    func loadNotificationSettings(deviceID: Int64) async throws -> NotificationSettings {
        guard let result = state.withLock({ $0.loadNotificationSettingsResult }) else {
            XCTFail("Could not find result for loading notification settings.")
            throw NetworkError.notFound()
        }
        return try result.get()
    }

    func updateNotificationSettings(with settings: NotificationSettings) async throws {
        switch state.withLock({ $0.updateNotificationSettingsResult }) {
        case .success:
            break
        case .failure(let error):
            throw error
        }
    }

    func createAccount(email: String,
                       username: String,
                       password: String,
                       clientID: String,
                       clientSecret: String) async -> Result<CreateAccountResult, CreateAccountError> {
        guard let result = state.withLock({ $0.createAccountResult }) else {
            XCTFail("Could not find result for creating an account.")
            return .failure(.unexpected(error: .empty()))
        }
        return result
    }

    func closeAccount() async throws {
        switch state.withLock({ $0.closeAccountResult }) {
        case .success:
            break
        case .failure(let error):
            throw error
        }
    }
}
