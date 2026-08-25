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
        try sut.save(endpoints, siteURL: "https://EXAMPLE.com/", username: "Merchant")

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
        try sut.save(expected, siteURL: "https://example.com/shop/", username: "Merchant")
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
        try sut.save(expected, siteURL: "http://example.com:80", username: "merchant")

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

    @Test func test_save_when_readback_fails_then_removes_exact_attempted_value() throws {
        // Given
        let defaults = try #require(ReadbackFailingUserDefaults(suiteName: UUID().uuidString))
        defer { clear(defaults) }
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: #require(URL(string: "https://example.com")))
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        defaults.failureMode = .dropSecondRead

        // When, Then
        #expect(throws: CookieNonceAuthenticationEndpointStore.StoreError.self) {
            try sut.save(endpoints, siteURL: "https://example.com", username: "merchant")
        }
        defaults.failureMode = .none
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == nil)
    }

    @Test func test_save_when_readback_fails_and_cleanup_removal_is_ignored_then_attempted_value_is_inert() throws {
        // Given
        let defaults = try #require(ReadbackFailingUserDefaults(suiteName: UUID().uuidString))
        defer { clear(defaults) }
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: #require(URL(string: "https://example.com")))
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        defaults.failureMode = .dropSecondRead
        defaults.retainNextEndpointRemoval = true

        // When, Then
        #expect(throws: CookieNonceAuthenticationEndpointStore.StoreError.self) {
            try sut.save(endpoints, siteURL: "https://example.com", username: "merchant")
        }
        defaults.failureMode = .none
        #expect(defaults.didRetainEndpointRemoval)
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == Data())
        #expect(sut.endpoints(siteURL: "https://example.com", username: "merchant") == nil)
    }

    @Test func test_save_when_endpoint_site_does_not_match_identity_then_preserves_existing_bytes() throws {
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

        // When, Then
        #expect(throws: CookieNonceAuthenticationEndpointStore.StoreError.self) {
            try sut.save(mismatchedEndpoints, siteURL: "https://example.com", username: "merchant")
        }
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == existingRecord)
    }

    @Test func test_save_when_concurrent_value_replaces_attempt_then_does_not_remove_replacement() throws {
        // Given
        let replacementDefaults = try makeDefaults()
        defer { clear(replacementDefaults) }
        let replacementEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://replacement.example")),
            loginEntryURL: #require(URL(string: "https://replacement.example/custom-login"))
        )
        try CookieNonceAuthenticationEndpointStore(userDefaults: replacementDefaults).save(
            replacementEndpoints,
            siteURL: "https://replacement.example",
            username: "replacement"
        )
        let replacementData = try #require(
            replacementDefaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)
        )
        let defaults = try #require(ReadbackFailingUserDefaults(suiteName: UUID().uuidString))
        defer { clear(defaults) }
        defaults.failureMode = .replaceOnSecondRead(replacementData)
        let attemptedEndpoints = try CookieNonceAuthenticationEndpoints(siteURL: #require(URL(string: "https://example.com")))
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)

        // When, Then
        #expect(throws: CookieNonceAuthenticationEndpointStore.StoreError.self) {
            try sut.save(attemptedEndpoints, siteURL: "https://example.com", username: "merchant")
        }
        defaults.failureMode = .none
        #expect(sut.endpoints(siteURL: "https://replacement.example", username: "replacement") == replacementEndpoints)
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
        try sut.remove(siteURL: "https://example.com", username: "Merchant")

        // Then
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == nil)
    }

    @Test func test_remove_when_readback_confirms_owned_record_remains_then_throws_without_discarding_it() throws {
        // Given
        let defaults = try #require(RemovalFailingUserDefaults(suiteName: UUID().uuidString))
        defer { clear(defaults) }
        let record = try recordData(siteURL: "https://example.com",
                                    username: "merchant",
                                    loginEntryURL: "https://example.com/custom-login",
                                    adminBaseURL: "https://example.com/wp-admin/")
        defaults.set(record, forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)
        defaults.failureMode = .retain
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)

        // When, Then
        #expect(throws: CookieNonceAuthenticationEndpointStore.StoreError.self) {
            try sut.remove(siteURL: "https://example.com", username: "merchant")
        }
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == record)
    }

    @Test func test_remove_when_concurrent_value_replaces_owned_record_then_throws_without_removing_replacement() throws {
        // Given
        let defaults = try #require(RemovalFailingUserDefaults(suiteName: UUID().uuidString))
        defer { clear(defaults) }
        let ownedRecord = try recordData(siteURL: "https://example.com",
                                         username: "merchant",
                                         loginEntryURL: "https://example.com/custom-login",
                                         adminBaseURL: "https://example.com/wp-admin/")
        let replacement = try recordData(siteURL: "https://other.example",
                                         username: "other",
                                         loginEntryURL: "https://other.example/login",
                                         adminBaseURL: "https://other.example/wp-admin/")
        defaults.set(ownedRecord, forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)
        defaults.failureMode = .replace(replacement)
        let sut = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)

        // When, Then
        #expect(throws: CookieNonceAuthenticationEndpointStore.StoreError.self) {
            try sut.remove(siteURL: "https://example.com", username: "merchant")
        }
        #expect(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue) == replacement)
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
        try removingStore.save(removingEndpoints, siteURL: "https://removing.example", username: "removing")
        defaults.pauseNextEndpointRemoval = true
        let removalResult = LockedOperationResult()
        let replacementResult = LockedOperationResult()
        let removalFinished = DispatchSemaphore(value: 0)
        let replacementStarted = DispatchSemaphore(value: 0)
        let replacementFinished = DispatchSemaphore(value: 0)

        // When
        DispatchQueue.global().async {
            removalResult.set(Result {
                try removingStore.remove(siteURL: "https://removing.example", username: "removing")
            })
            removalFinished.signal()
        }
        #expect(defaults.removalReached.wait(timeout: .now() + 5) == .success)
        DispatchQueue.global().async {
            replacementStarted.signal()
            replacementResult.set(Result {
                try replacementStore.save(
                    replacementEndpoints,
                    siteURL: "https://replacement.example",
                    username: "replacement"
                )
            })
            replacementFinished.signal()
        }
        #expect(replacementStarted.wait(timeout: .now() + 5) == .success)

        // Then
        #expect(replacementFinished.wait(timeout: .now() + 0.1) == .timedOut)
        defaults.continueRemoval.signal()
        #expect(removalFinished.wait(timeout: .now() + 5) == .success)
        #expect(replacementFinished.wait(timeout: .now() + 5) == .success)
        #expect(removalResult.succeeded)
        #expect(replacementResult.succeeded)
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
        try removingStore.save(staleEndpoints, siteURL: "https://stale.example", username: "stale")
        defaults.pauseNextEndpointRemoval = true
        let replacementResult = LockedOperationResult()
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
            replacementResult.set(Result {
                try replacementStore.save(
                    replacementEndpoints,
                    siteURL: "https://replacement.example",
                    username: "replacement"
                )
            })
            replacementFinished.signal()
        }
        #expect(replacementStarted.wait(timeout: .now() + 5) == .success)

        // Then
        #expect(replacementFinished.wait(timeout: .now() + 0.1) == .timedOut)
        defaults.continueRemoval.signal()
        #expect(removalFinished.wait(timeout: .now() + 5) == .success)
        #expect(replacementFinished.wait(timeout: .now() + 5) == .success)
        #expect(replacementResult.succeeded)
        #expect(
            replacementStore.endpoints(siteURL: "https://replacement.example", username: "replacement") == replacementEndpoints
        )
    }

    @Test func test_save_rollback_when_replacement_save_starts_immediately_before_cleanup_then_serializes_and_preserves_replacement() throws {
        // Given
        let defaults = try #require(BlockingRemovalUserDefaults(suiteName: UUID().uuidString))
        defer { clear(defaults) }
        let failingStore = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        let replacementStore = CookieNonceAuthenticationEndpointStore(userDefaults: defaults)
        let failingEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://failing.example")),
            loginEntryURL: #require(URL(string: "https://failing.example/custom-login"))
        )
        let replacementEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://replacement.example")),
            loginEntryURL: #require(URL(string: "https://replacement.example/custom-login"))
        )
        defaults.failEndpointReadNumber = 2
        defaults.pauseNextEndpointRemoval = true
        let failingResult = LockedOperationResult()
        let replacementResult = LockedOperationResult()
        let failingSaveFinished = DispatchSemaphore(value: 0)
        let replacementStarted = DispatchSemaphore(value: 0)
        let replacementFinished = DispatchSemaphore(value: 0)

        // When
        DispatchQueue.global().async {
            failingResult.set(Result {
                try failingStore.save(failingEndpoints, siteURL: "https://failing.example", username: "failing")
            })
            failingSaveFinished.signal()
        }
        #expect(defaults.removalReached.wait(timeout: .now() + 5) == .success)
        DispatchQueue.global().async {
            replacementStarted.signal()
            replacementResult.set(Result {
                try replacementStore.save(
                    replacementEndpoints,
                    siteURL: "https://replacement.example",
                    username: "replacement"
                )
            })
            replacementFinished.signal()
        }
        #expect(replacementStarted.wait(timeout: .now() + 5) == .success)

        // Then
        #expect(replacementFinished.wait(timeout: .now() + 0.1) == .timedOut)
        defaults.continueRemoval.signal()
        #expect(failingSaveFinished.wait(timeout: .now() + 5) == .success)
        #expect(replacementFinished.wait(timeout: .now() + 5) == .success)
        #expect(failingResult.failed)
        #expect(replacementResult.succeeded)
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

private final class ReadbackFailingUserDefaults: UserDefaults, @unchecked Sendable {
    enum FailureMode {
        case none
        case dropSecondRead
        case replaceOnSecondRead(Data)
    }

    var failureMode = FailureMode.none
    var retainNextEndpointRemoval = false
    private(set) var didRetainEndpointRemoval = false
    private var readCount = 0

    override func set(_ value: Any?, forKey defaultName: String) {
        super.set(value, forKey: defaultName)
        if defaultName == UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue {
            readCount = 0
        }
    }

    override func data(forKey defaultName: String) -> Data? {
        guard defaultName == UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue else {
            return super.data(forKey: defaultName)
        }
        readCount += 1
        guard readCount == 2 else {
            return super.data(forKey: defaultName)
        }
        switch failureMode {
        case .none:
            return super.data(forKey: defaultName)
        case .dropSecondRead:
            return nil
        case .replaceOnSecondRead(let replacement):
            super.set(replacement, forKey: defaultName)
            return nil
        }
    }

    override func removeObject(forKey defaultName: String) {
        if defaultName == UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue,
           retainNextEndpointRemoval {
            retainNextEndpointRemoval = false
            didRetainEndpointRemoval = true
            return
        }
        super.removeObject(forKey: defaultName)
    }
}

private final class RemovalFailingUserDefaults: UserDefaults, @unchecked Sendable {
    enum FailureMode {
        case none
        case retain
        case replace(Data)
    }

    var failureMode = FailureMode.none

    override func removeObject(forKey defaultName: String) {
        guard defaultName == UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue else {
            return super.removeObject(forKey: defaultName)
        }
        let failureMode = self.failureMode
        self.failureMode = .none
        switch failureMode {
        case .none:
            super.removeObject(forKey: defaultName)
        case .retain:
            return
        case .replace(let replacement):
            super.set(replacement, forKey: defaultName)
        }
    }
}

private final class BlockingRemovalUserDefaults: UserDefaults, @unchecked Sendable {
    var pauseNextEndpointRemoval = false
    var failEndpointReadNumber: Int?
    let removalReached = DispatchSemaphore(value: 0)
    let continueRemoval = DispatchSemaphore(value: 0)
    private var endpointReadCount = 0

    override func set(_ value: Any?, forKey defaultName: String) {
        if defaultName == UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue {
            endpointReadCount = 0
        }
        super.set(value, forKey: defaultName)
    }

    override func data(forKey defaultName: String) -> Data? {
        guard defaultName == UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue else {
            return super.data(forKey: defaultName)
        }
        endpointReadCount += 1
        guard endpointReadCount == failEndpointReadNumber else {
            return super.data(forKey: defaultName)
        }
        failEndpointReadNumber = nil
        return nil
    }

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

private final class LockedOperationResult: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<Void, Error>?

    var succeeded: Bool {
        lock.lock()
        defer { lock.unlock() }
        guard case .success? = result else {
            return false
        }
        return true
    }

    var failed: Bool {
        lock.lock()
        defer { lock.unlock() }
        guard case .failure? = result else {
            return false
        }
        return true
    }

    func set(_ result: Result<Void, Error>) {
        lock.lock()
        self.result = result
        lock.unlock()
    }
}
