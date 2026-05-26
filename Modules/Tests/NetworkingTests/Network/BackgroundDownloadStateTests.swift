import Foundation
import Testing
@testable import Networking

struct BackgroundDownloadStateTests {
    private let store: BackgroundDownloadStateStore

    init() {
        // Create isolated UserDefaults suite for this test
        let testDefaults = UserDefaults(suiteName: "BackgroundDownloadStateTests.\(UUID().uuidString)")!
        store = BackgroundDownloadStateStore(userDefaults: testDefaults)
    }

    @Test func save_persists_state_to_userdefaults() {
        // Given
        let state = BackgroundDownloadState(
            sessionIdentifier: "test.session.123",
            siteID: 456
        )

        // When
        store.save(state)

        // Then
        let loaded = store.load(for: "test.session.123")
        #expect(loaded?.sessionIdentifier == "test.session.123")
        #expect(loaded?.siteID == 456)
    }

    @Test func load_returns_nil_for_nonexistent_session() {
        // When
        let loaded = store.load(for: "nonexistent.session")

        // Then
        #expect(loaded == nil)
    }

    @Test func load_returns_nil_for_different_session_identifier() {
        // Given
        let state = BackgroundDownloadState(
            sessionIdentifier: "session.A",
            siteID: 123
        )
        store.save(state)

        // When
        let loaded = store.load(for: "session.B")

        // Then
        #expect(loaded == nil)
    }

    @Test func clear_removes_saved_state() {
        // Given
        let state = BackgroundDownloadState(
            sessionIdentifier: "test.session",
            siteID: 789
        )
        store.save(state)

        // When
        store.clear()

        // Then
        let loaded = store.load(for: "test.session")
        #expect(loaded == nil)
    }

    @Test func save_overwrites_previous_state() {
        // Given
        let firstState = BackgroundDownloadState(
            sessionIdentifier: "session.1",
            siteID: 100
        )
        store.save(firstState)

        let secondState = BackgroundDownloadState(
            sessionIdentifier: "session.2",
            siteID: 200
        )

        // When
        store.save(secondState)

        // Then
        let loadedFirst = store.load(for: "session.1")
        let loadedSecond = store.load(for: "session.2")

        #expect(loadedFirst == nil) // First session is overwritten
        #expect(loadedSecond?.sessionIdentifier == "session.2")
        #expect(loadedSecond?.siteID == 200)
    }
}
