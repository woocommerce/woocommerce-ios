import Foundation
import Yosemite

/// Persists the non-secret, identity-bound endpoint configuration used by cookie-nonce authentication.
struct CookieNonceAuthenticationEndpointStore {
    enum StoreError: Error {
        case invalidIdentity
        case persistenceFailed
    }

    private let userDefaults: UserDefaults
    private static let synchronizationLock = NSLock()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func endpoints(siteURL: String, username: String) -> CookieNonceAuthenticationEndpoints? {
        withLock {
            endpointsUnlocked(siteURL: siteURL, username: username)
        }
    }

    func save(_ endpoints: CookieNonceAuthenticationEndpoints, siteURL: String, username: String) throws {
        try withLock {
            guard let canonicalSiteURL = canonicalSiteURL(siteURL: siteURL, username: username),
                  canonicalSiteURL == endpoints.siteURL else {
                throw StoreError.invalidIdentity
            }

            let record = Record(siteURL: endpoints.siteURL.absoluteString,
                                username: username,
                                loginEntryURL: endpoints.loginEntryURL.absoluteString,
                                adminBaseURL: endpoints.adminBaseURL.absoluteString)
            let attemptedData = try PropertyListEncoder().encode(record)
            userDefaults.set(attemptedData, forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)

            guard userDefaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == attemptedData,
                  endpointsUnlocked(siteURL: siteURL, username: username) == endpoints else {
                invalidateAttemptedDataIfUnchangedUnlocked(attemptedData)
                throw StoreError.persistenceFailed
            }
        }
    }

    func remove() {
        withLock {
            removeUnlocked()
        }
    }

    /// Removes a record that does not belong to the identity without allowing another store operation between validation and removal.
    func removeUnlessOwned(siteURL: String, username: String) {
        withLock {
            guard endpointsUnlocked(siteURL: siteURL, username: username) == nil else {
                return
            }
            removeUnlocked()
        }
    }

    func remove(siteURL: String, username: String) throws {
        try withLock {
            guard let ownedData = userDefaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue),
                  let record = try? PropertyListDecoder().decode(Record.self, from: ownedData),
                  record.username == username,
                  let canonicalSiteURL = canonicalSiteURL(siteURL: siteURL, username: username),
                  let storedSiteURL = URL(string: record.siteURL),
                  let storedEndpoints = try? CookieNonceAuthenticationEndpoints(siteURL: storedSiteURL),
                  canonicalSiteURL == storedEndpoints.siteURL else {
                return
            }
            guard userDefaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == ownedData else {
                throw StoreError.persistenceFailed
            }
            removeUnlocked()
            guard userDefaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == nil else {
                throw StoreError.persistenceFailed
            }
        }
    }
}

private extension CookieNonceAuthenticationEndpointStore {
    struct Record: Codable {
        let siteURL: String
        let username: String
        let loginEntryURL: String
        let adminBaseURL: String
    }

    func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        Self.synchronizationLock.lock()
        defer { Self.synchronizationLock.unlock() }
        return try operation()
    }

    func endpointsUnlocked(siteURL: String, username: String) -> CookieNonceAuthenticationEndpoints? {
        guard let data = userDefaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue),
              let record = try? PropertyListDecoder().decode(Record.self, from: data),
              record.username == username,
              let canonicalSiteURL = canonicalSiteURL(siteURL: siteURL, username: username),
              let storedSiteURL = URL(string: record.siteURL),
              let loginEntryURL = URL(string: record.loginEntryURL),
              let adminBaseURL = URL(string: record.adminBaseURL),
              let endpoints = try? CookieNonceAuthenticationEndpoints(
                  siteURL: storedSiteURL,
                  loginEntryURL: loginEntryURL,
                  adminBaseURL: adminBaseURL
              ),
              endpoints.siteURL == canonicalSiteURL,
              record.siteURL == endpoints.siteURL.absoluteString,
              record.loginEntryURL == endpoints.loginEntryURL.absoluteString,
              record.adminBaseURL == endpoints.adminBaseURL.absoluteString else {
            return nil
        }
        return endpoints
    }

    /// The normalized site URL a record must be bound to, or `nil` when the identity is not usable.
    ///
    func canonicalSiteURL(siteURL: String, username: String) -> URL? {
        guard username.isEmpty == false,
              let siteURL = URL(string: siteURL),
              let endpoints = try? CookieNonceAuthenticationEndpoints(siteURL: siteURL) else {
            return nil
        }
        return endpoints.siteURL
    }

    func invalidateAttemptedDataIfUnchangedUnlocked(_ attemptedData: Data) {
        let key = UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue
        guard userDefaults.data(forKey: key) == attemptedData else {
            return
        }
        removeUnlocked()
        guard userDefaults.data(forKey: key) == attemptedData else {
            return
        }
        userDefaults.set(Data(), forKey: key)
    }

    func removeUnlocked() {
        userDefaults.removeObject(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)
    }
}
