import Foundation
import Yosemite

/// Persists the non-secret, identity-bound endpoint configuration used by cookie-nonce authentication.
struct CookieNonceAuthenticationEndpointStore {
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

    func save(_ endpoints: CookieNonceAuthenticationEndpoints, siteURL: String, username: String) {
        withLock {
            guard let canonicalSiteURL = canonicalSiteURL(siteURL: siteURL, username: username),
                  canonicalSiteURL == endpoints.siteURL else {
                return
            }

            let record = Record(siteURL: endpoints.siteURL.absoluteString,
                                username: username,
                                loginEntryURL: endpoints.loginEntryURL.absoluteString,
                                adminBaseURL: endpoints.adminBaseURL.absoluteString)
            let data: Data
            do {
                data = try PropertyListEncoder().encode(record)
            } catch {
                DDLogError("⛔️ Error encoding cookie nonce authentication endpoints: \(error)")
                return
            }
            userDefaults.set(data, forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)
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

    func remove(siteURL: String, username: String) {
        withLock {
            guard let data = userDefaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue),
                  let record = try? PropertyListDecoder().decode(Record.self, from: data),
                  record.username == username,
                  let canonicalSiteURL = canonicalSiteURL(siteURL: siteURL, username: username),
                  let storedSiteURL = URL(string: record.siteURL),
                  let storedEndpoints = try? CookieNonceAuthenticationEndpoints(siteURL: storedSiteURL),
                  canonicalSiteURL == storedEndpoints.siteURL else {
                return
            }
            removeUnlocked()
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

    func withLock<T>(_ operation: () -> T) -> T {
        Self.synchronizationLock.lock()
        defer { Self.synchronizationLock.unlock() }
        return operation()
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

    func removeUnlocked() {
        userDefaults.removeObject(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)
    }
}
