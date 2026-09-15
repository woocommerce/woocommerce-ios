import Foundation
import Testing
import Yosemite
@testable import WooCommerce

struct CookieNonceAuthenticationEndpointStoreTests {
    @Test func test_save_when_record_is_valid_then_persists_only_four_non_secret_fields() throws {
        // Given
        let defaults = try makeDefaults()
        defer { clear(defaults) }
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://example.com")),
            loginEntryURL: #require(URL(string: "https://example.com/custom-login")),
            adminBaseURL: #require(URL(string: "https://example.com/private-admin"))
        )
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)

        // When
        sut.save(endpoints, siteURL: "https://EXAMPLE.com/", username: "Merchant")

        // Then
        let data = try #require(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue))
        let record = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String])
        #expect(record.count == 4)
        #expect(record["siteURL"] == "https://example.com")
        #expect(record["username"] == "Merchant")
        #expect(record["loginEntryURL"] == "https://example.com/custom-login")
        #expect(record["adminBaseURL"] == "https://example.com/private-admin/")
        #expect(String(decoding: data, as: UTF8.self).contains("password") == false)
        #expect(String(decoding: data, as: UTF8.self).contains("nonce") == false)
    }

    @Test func test_endpoints_when_identity_matches_then_restores_normalized_endpoints() throws {
        // Given
        let defaults = try makeDefaults()
        defer { clear(defaults) }
        let expected = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://example.com/shop")),
            loginEntryURL: #require(URL(string: "https://example.com/shop/sign-in")),
            adminBaseURL: #require(URL(string: "https://example.com/shop/control"))
        )
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        sut.save(expected, siteURL: "https://example.com/shop/", username: "Merchant")
        let rawRecord = try #require(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue))

        // When
        let restored = sut.endpoints(siteURL: "https://EXAMPLE.com/shop", username: "Merchant")

        // Then
        #expect(restored == expected)
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == rawRecord)
        #expect(sut.endpoints(siteURL: "https://example.com/shop", username: "merchant") == nil)
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == rawRecord)
        #expect(sut.endpoints(siteURL: "https://example.com/other", username: "Merchant") == nil)
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == rawRecord)
    }

    @Test func test_endpoints_when_http_site_promotes_default_port_endpoints_to_https_then_restores() throws {
        // Given
        let defaults = try makeDefaults()
        defer { clear(defaults) }
        let expected = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "http://example.com")),
            loginEntryURL: #require(URL(string: "https://example.com/custom-login")),
            adminBaseURL: #require(URL(string: "https://example.com/private-admin"))
        )
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)

        // When
        sut.save(expected, siteURL: "http://example.com:80", username: "merchant")

        // Then
        #expect(sut.endpoints(siteURL: "http://example.com", username: "merchant") == expected)
    }

    @Test func test_endpoints_when_record_is_corrupt_noncanonical_or_off_origin_then_is_inert() throws {
        // Given
        let defaults = try makeDefaults()
        defer { clear(defaults) }
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        let invalidRecords = [
            Data("not a property list".utf8),
            try recordData(siteURL: "https://EXAMPLE.com/",
                           username: "merchant",
                           loginEntryURL: "https://example.com/custom-login",
                           adminBaseURL: "https://example.com/wp-admin/"),
            try recordData(siteURL: "https://example.com",
                           username: "merchant",
                           loginEntryURL: "https://attacker.example/custom-login",
                           adminBaseURL: "https://example.com/wp-admin/"),
            try recordData(siteURL: "https://example.com",
                           username: "merchant",
                           loginEntryURL: "http://example.com/custom-login",
                           adminBaseURL: "https://example.com/wp-admin/")
        ]

        for record in invalidRecords {
            // When
            defaults.set(record, forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)

            // Then
            #expect(sut.endpoints(siteURL: "https://example.com", username: "merchant") == nil)
            #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == record)
        }
    }

    @Test func test_save_when_endpoint_site_does_not_match_identity_then_ignores_write() throws {
        // Given
        let defaults = try makeDefaults()
        defer { clear(defaults) }
        let existingRecord = try recordData(siteURL: "https://existing.example",
                                            username: "existing",
                                            loginEntryURL: "https://existing.example/login",
                                            adminBaseURL: "https://existing.example/wp-admin/")
        defaults.set(existingRecord, forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)
        let mismatchedEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://other.example"))
        )
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)

        // When
        sut.save(mismatchedEndpoints, siteURL: "https://example.com", username: "merchant")

        // Then
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == existingRecord)
    }

    @Test func test_remove_when_identity_matches_corrupt_endpoints_then_removes_record() throws {
        // Given
        let defaults = try makeDefaults()
        defer { clear(defaults) }
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        defaults.set(
            try recordData(siteURL: "https://EXAMPLE.com/",
                           username: "Merchant",
                           loginEntryURL: "https://attacker.example/login",
                           adminBaseURL: "https://example.com/wp-admin/"),
            forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue
        )

        // When
        sut.remove(siteURL: "https://example.com", username: "Merchant")

        // Then
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == nil)
    }

    @Test func test_remove_when_replacement_save_starts_immediately_before_removal_then_serializes_and_preserves_replacement() throws {
        // Given
        let defaults = try #require(BlockingRemovalUserDefaults(suiteName: UUID().uuidString))
        defer { clear(defaults) }
        let removingStore = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        let replacementStore = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        let removingEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://removing.example")),
            loginEntryURL: #require(URL(string: "https://removing.example/custom-login"))
        )
        let replacementEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://replacement.example")),
            loginEntryURL: #require(URL(string: "https://replacement.example/custom-login"))
        )
        removingStore.save(removingEndpoints, siteURL: "https://removing.example", username: "removing")
        defaults.pauseNextEndpointRemoval = true
        let removalFinished = DispatchSemaphore(value: 0)
        let replacementStarted = DispatchSemaphore(value: 0)
        let replacementFinished = DispatchSemaphore(value: 0)

        // When
        DispatchQueue.global().async {
            removingStore.remove(siteURL: "https://removing.example", username: "removing")
            removalFinished.signal()
        }
        #expect(defaults.removalReached.wait(timeout: .now() + 5) == .success)
        DispatchQueue.global().async {
            replacementStarted.signal()
            replacementStore.save(
                replacementEndpoints,
                siteURL: "https://replacement.example",
                username: "replacement"
            )
            replacementFinished.signal()
        }
        #expect(replacementStarted.wait(timeout: .now() + 5) == .success)

        // Then
        #expect(replacementFinished.wait(timeout: .now() + 0.1) == .timedOut)
        defaults.continueRemoval.signal()
        #expect(removalFinished.wait(timeout: .now() + 5) == .success)
        #expect(replacementFinished.wait(timeout: .now() + 5) == .success)
        #expect(
            replacementStore.endpoints(siteURL: "https://replacement.example", username: "replacement") == replacementEndpoints
        )
    }

    @Test func test_removeUnlessOwned_when_replacement_save_starts_after_ownership_check_then_serializes_and_preserves_replacement() throws {
        // Given
        let defaults = try #require(BlockingRemovalUserDefaults(suiteName: UUID().uuidString))
        defer { clear(defaults) }
        let removingStore = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        let replacementStore = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        let staleEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://stale.example")),
            loginEntryURL: #require(URL(string: "https://stale.example/custom-login"))
        )
        let replacementEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://replacement.example")),
            loginEntryURL: #require(URL(string: "https://replacement.example/custom-login"))
        )
        removingStore.save(staleEndpoints, siteURL: "https://stale.example", username: "stale")
        defaults.pauseNextEndpointRemoval = true
        let removalFinished = DispatchSemaphore(value: 0)
        let replacementStarted = DispatchSemaphore(value: 0)
        let replacementFinished = DispatchSemaphore(value: 0)

        // When
        DispatchQueue.global().async {
            removingStore.removeUnlessOwned(siteURL: "https://incoming.example", username: "incoming")
            removalFinished.signal()
        }
        // Reaching `removeObject` proves ownership validation has completed while the shared lock remains held.
        #expect(defaults.removalReached.wait(timeout: .now() + 5) == .success)
        DispatchQueue.global().async {
            replacementStarted.signal()
            replacementStore.save(
                replacementEndpoints,
                siteURL: "https://replacement.example",
                username: "replacement"
            )
            replacementFinished.signal()
        }
        #expect(replacementStarted.wait(timeout: .now() + 5) == .success)

        // Then
        #expect(replacementFinished.wait(timeout: .now() + 0.1) == .timedOut)
        defaults.continueRemoval.signal()
        #expect(removalFinished.wait(timeout: .now() + 5) == .success)
        #expect(replacementFinished.wait(timeout: .now() + 5) == .success)
        #expect(
            replacementStore.endpoints(siteURL: "https://replacement.example", username: "replacement") == replacementEndpoints
        )
    }
}

private extension CookieNonceAuthenticationEndpointStoreTests {
    func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: UUID().uuidString))
    }

    func clear(_ defaults: UserDefaults) {
        defaults.removeObject(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)
    }

    func recordData(siteURL: String, username: String, loginEntryURL: String, adminBaseURL: String) throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: [
                "siteURL": siteURL,
                "username": username,
                "loginEntryURL": loginEntryURL,
                "adminBaseURL": adminBaseURL
            ],
            format: .binary,
            options: 0
        )
    }
}

private final class BlockingRemovalUserDefaults: UserDefaults, @unchecked Sendable {
    var pauseNextEndpointRemoval = false
    let removalReached = DispatchSemaphore(value: 0)
    let continueRemoval = DispatchSemaphore(value: 0)

    override func removeObject(forKey defaultName: String) {
        if defaultName == UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue,
           pauseNextEndpointRemoval {
            pauseNextEndpointRemoval = false
            removalReached.signal()
            _ = continueRemoval.wait(timeout: .now() + 5)
        }
        super.removeObject(forKey: defaultName)
    }
}
