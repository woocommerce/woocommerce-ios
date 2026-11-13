import Foundation
import Testing
@testable import WooCommerce

struct UserDefaultsSignificantChangeConsentStoreTests {
    private let ratingChange = SignificantChangeIdentifier.ageRatingChange(ratingCode: 13)

    // MARK: - Status

    @Test func status_when_nothing_stored_then_returns_nil() throws {
        // Given
        let (sut, cleanup) = try makeStore()
        defer { cleanup() }

        // Then
        #expect(sut.status(for: ratingChange) == nil)
    }

    @Test(arguments: [SignificantChangeConsentStatus.granted, .denied, .pending])
    func setStatus_when_read_back_then_round_trips(status: SignificantChangeConsentStatus) throws {
        // Given
        let (sut, cleanup) = try makeStore()
        defer { cleanup() }

        // When
        sut.setStatus(status, for: ratingChange)

        // Then
        #expect(sut.status(for: ratingChange) == status)
        #expect(sut.status(for: .ageRatingChange(ratingCode: 14)) == nil)
    }

    @Test func setStatus_when_called_again_then_overwrites_previous_status() throws {
        // Given
        let (sut, cleanup) = try makeStore()
        defer { cleanup() }
        sut.setStatus(.denied, for: ratingChange)

        // When
        sut.setStatus(.pending, for: ratingChange)

        // Then
        #expect(sut.status(for: ratingChange) == .pending)
    }

    // MARK: - Pending request

    @Test(arguments: [
        SignificantChangeIdentifier.ageRatingChange(ratingCode: 13),
        .manual(id: "new-feature"),
        .manual(id: "v2.1.checkout-redesign")
    ])
    func setPendingRequest_when_read_back_then_round_trips(identifier: SignificantChangeIdentifier) throws {
        // Given
        let (sut, cleanup) = try makeStore()
        defer { cleanup() }
        let request = PendingConsentRequest(questionID: UUID(), identifier: identifier)

        // When
        sut.setPendingRequest(request)

        // Then
        #expect(sut.pendingRequest == request)
    }

    @Test func clearPendingRequest_when_called_then_pendingRequest_is_nil() throws {
        // Given
        let (sut, cleanup) = try makeStore()
        defer { cleanup() }
        sut.setPendingRequest(PendingConsentRequest(questionID: UUID(), identifier: ratingChange))

        // When
        sut.clearPendingRequest()

        // Then
        #expect(sut.pendingRequest == nil)
    }

    // MARK: - Reset

    @Test func resetAll_when_called_then_removes_every_status_and_the_pending_request() throws {
        // Given
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let sut = UserDefaultsSignificantChangeConsentStore(defaults: defaults)
        let manual = SignificantChangeIdentifier.manual(id: "new-feature")
        sut.setStatus(.granted, for: ratingChange)
        sut.setStatus(.denied, for: manual)
        sut.setPendingRequest(PendingConsentRequest(questionID: UUID(), identifier: manual))
        defaults.set("keep", forKey: "unrelated.key")

        // When
        UserDefaultsSignificantChangeConsentStore.resetAll(in: defaults)

        // Then
        #expect(sut.status(for: ratingChange) == nil)
        #expect(sut.status(for: manual) == nil)
        #expect(sut.pendingRequest == nil)
        #expect(defaults.string(forKey: "unrelated.key") == "keep")
    }
}

struct SignificantChangeIdentifierCacheKeyTests {
    @Test(arguments: [
        SignificantChangeIdentifier.ageRatingChange(ratingCode: 13),
        .ageRatingChange(ratingCode: 0),
        .manual(id: "new-feature"),
        .manual(id: "v2.1.checkout-redesign")
    ])
    func init_cacheKey_when_given_own_cacheKey_then_round_trips(identifier: SignificantChangeIdentifier) {
        #expect(SignificantChangeIdentifier(cacheKey: identifier.cacheKey) == identifier)
    }

    @Test func cacheKey_when_identifiers_differ_then_keys_differ() {
        #expect(SignificantChangeIdentifier.ageRatingChange(ratingCode: 13).cacheKey
                != SignificantChangeIdentifier.ageRatingChange(ratingCode: 14).cacheKey)
        #expect(SignificantChangeIdentifier.manual(id: "13").cacheKey
                != SignificantChangeIdentifier.ageRatingChange(ratingCode: 13).cacheKey)
    }

    @Test(arguments: ["", "nodot", "unknownKind.1", "ageRatingChange.notANumber", "ageRatingChange.", ".13"])
    func init_cacheKey_when_malformed_then_returns_nil(cacheKey: String) {
        #expect(SignificantChangeIdentifier(cacheKey: cacheKey) == nil)
    }
}

private extension UserDefaultsSignificantChangeConsentStoreTests {
    func makeDefaults() throws -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "UserDefaultsSignificantChangeConsentStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        return (defaults, suiteName)
    }

    func makeStore() throws -> (store: UserDefaultsSignificantChangeConsentStore, cleanup: () -> Void) {
        let (defaults, suiteName) = try makeDefaults()
        return (
            UserDefaultsSignificantChangeConsentStore(defaults: defaults),
            { defaults.removePersistentDomain(forName: suiteName) }
        )
    }
}
