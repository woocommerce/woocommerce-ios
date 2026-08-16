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
            guard let identity = canonicalIdentity(siteURL: siteURL, username: username),
                  identity.siteURL == endpoints.siteURL else {
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

    func remove(siteURL: String, username: String) throws {
        try withLock {
            guard let ownedData = userDefaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue),
                  let record = try? PropertyListDecoder().decode(Record.self, from: ownedData),
                  record.username == username,
                  let identity = canonicalIdentity(siteURL: siteURL, username: username),
                  let storedSiteURL = URL(string: record.siteURL),
                  let storedIdentity = try? CookieNonceAuthenticationEndpoints(siteURL: storedSiteURL),
                  identity.siteURL == storedIdentity.siteURL else {
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
    struct Identity {
        let siteURL: URL
        let username: String
    }

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
              let canonicalIdentity = canonicalIdentity(siteURL: siteURL, username: username),
              let storedSiteURL = URL(string: record.siteURL),
              let loginEntryURL = URL(string: record.loginEntryURL),
              let adminBaseURL = URL(string: record.adminBaseURL),
              let endpoints = try? CookieNonceAuthenticationEndpoints(
                  siteURL: storedSiteURL,
                  loginEntryURL: loginEntryURL,
                  adminBaseURL: adminBaseURL
              ),
              endpoints.siteURL == canonicalIdentity.siteURL,
              record.siteURL == endpoints.siteURL.absoluteString,
              record.loginEntryURL == endpoints.loginEntryURL.absoluteString,
              record.adminBaseURL == endpoints.adminBaseURL.absoluteString else {
            return nil
        }
        return endpoints
    }

    func canonicalIdentity(siteURL: String, username: String) -> Identity? {
        guard username.isEmpty == false,
              let siteURL = URL(string: siteURL),
              let endpoints = try? CookieNonceAuthenticationEndpoints(siteURL: siteURL) else {
            return nil
        }
        return Identity(siteURL: endpoints.siteURL, username: username)
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
