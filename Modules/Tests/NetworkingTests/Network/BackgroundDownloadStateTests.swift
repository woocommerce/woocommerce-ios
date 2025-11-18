import Foundation
import Testing
@testable import Networking

struct BackgroundDownloadStateTests {
    private let testDefaults: UserDefaults

    init() {
        // Create isolated UserDefaults suite for this test
        testDefaults = UserDefaults(suiteName: "BackgroundDownloadStateTests.\(UUID().uuidString)")!
        BackgroundDownloadState.configure(userDefaults: testDefaults)
    }

    @Test func save_persists_state_to_userdefaults() {
        // Given
        let state = BackgroundDownloadState(
            sessionIdentifier: "test.session.123",
            siteID: 456
        )

        // When
        BackgroundDownloadState.save(state)

        // Then
        let loaded = BackgroundDownloadState.load(for: "test.session.123")
        #expect(loaded?.sessionIdentifier == "test.session.123")
        #expect(loaded?.siteID == 456)
    }

    @Test func load_returns_nil_for_nonexistent_session() {
        // When
        let loaded = BackgroundDownloadState.load(for: "nonexistent.session")

        // Then
        #expect(loaded == nil)
    }

    @Test func load_returns_nil_for_different_session_identifier() {
        // Given
        let state = BackgroundDownloadState(
            sessionIdentifier: "session.A",
            siteID: 123
        )
        BackgroundDownloadState.save(state)

        // When
        let loaded = BackgroundDownloadState.load(for: "session.B")

        // Then
        #expect(loaded == nil)
    }

    @Test func clear_removes_saved_state() {
        // Given
        let state = BackgroundDownloadState(
            sessionIdentifier: "test.session",
            siteID: 789
        )
        BackgroundDownloadState.save(state)

        // When
        BackgroundDownloadState.clear()

        // Then
        let loaded = BackgroundDownloadState.load(for: "test.session")
        #expect(loaded == nil)
    }

    @Test func save_overwrites_previous_state() {
        // Given
        let firstState = BackgroundDownloadState(
            sessionIdentifier: "session.1",
            siteID: 100
        )
        BackgroundDownloadState.save(firstState)

        let secondState = BackgroundDownloadState(
            sessionIdentifier: "session.2",
            siteID: 200
        )

        // When
        BackgroundDownloadState.save(secondState)

        // Then
        let loadedFirst = BackgroundDownloadState.load(for: "session.1")
        let loadedSecond = BackgroundDownloadState.load(for: "session.2")

        #expect(loadedFirst == nil) // First session is overwritten
        #expect(loadedSecond?.sessionIdentifier == "session.2")
        #expect(loadedSecond?.siteID == 200)
    }
}
