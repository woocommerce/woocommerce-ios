import SwiftUI
import Testing
@testable import PointOfSale

@MainActor
struct POSModalManagerTests {
    @Test func test_present_when_locked_or_covered_then_ignores_ordinary_modal() {
        // Given
        let sut = POSModalManager()
        let session = MockPOSAccessSession(isLocked: true)

        // When
        sut.present(compactStyle: .dialog, session: session, onDismiss: {}) { EmptyView() }

        // Then
        #expect(!sut.isPresented)

        // When
        sut.present(compactStyle: .cardReaderConnection, isCovered: true, onDismiss: {}) { EmptyView() }

        // Then
        #expect(!sut.isPresented)
    }

    @Test func test_dismiss_when_callback_changes_access_scope_then_ignores_completion() {
        // Given
        let sut = POSModalManager()
        let session = MockPOSAccessSession()
        sut.present(compactStyle: .dialog, session: session, onDismiss: { session.endSession() },
                    onDismissCompleted: { Issue.record("Completion ran for an expired session") }) { EmptyView() }

        // When
        sut.dismiss()

        // Then
        #expect(!sut.isPresented)
    }

    @Test func test_lock_when_ordinary_dialog_is_presented_then_discards_it_without_running_actions() {
        // Given
        let sut = POSModalManager()
        sut.present(compactStyle: .dialog, onDismiss: { Issue.record("Dismiss callback ran on lock") },
                    onDismissCompleted: { Issue.record("Completion ran on lock") }) { EmptyView() }

        // When
        sut.dismissForLock()

        // Then
        #expect(!sut.isPresented)
    }

    @Test func test_lock_when_reader_is_presented_then_keeps_it_and_ignores_another_owners_dismissal() {
        // Given
        let sut = POSModalManager()
        let session = MockPOSAccessSession()
        let readerOwner = UUID()
        var readerDismissCount = 0
        sut.present(compactStyle: .cardReaderConnection, owner: readerOwner, session: session,
                    onDismiss: { readerDismissCount += 1 }) { EmptyView() }

        // When
        session.lock()
        sut.dismissForLock()
        sut.dismiss(owner: UUID())

        // Then
        #expect(sut.isPresented)
        #expect(readerDismissCount == 0)
        session.isLocked = false
        sut.dismiss(owner: readerOwner)
        #expect(readerDismissCount == 1)
    }

    @Test func test_dismiss_when_reader_presentation_ends_during_lock_then_skips_its_actions() {
        // Given
        let sut = POSModalManager()
        let session = MockPOSAccessSession(isLocked: true)
        sut.present(compactStyle: .cardReaderConnection, session: session,
                    onDismiss: { Issue.record("Dismiss action ran during lock") }) { EmptyView() }
        #expect(sut.isPresented)

        // When
        sut.dismiss()

        // Then
        #expect(!sut.isPresented)
    }

    @Test func test_present_when_compactStyle_is_dialog_then_stores_dialog() {
        // Given
        let sut = POSModalManager()

        // When
        sut.present(compactStyle: .dialog, onDismiss: {}) { EmptyView() }

        // Then
        #expect(sut.isPresented)
        #expect(sut.compactStyle == .dialog)
    }

    @Test func test_present_when_compactStyle_is_fullScreen_then_stores_its_title() {
        // Given
        let sut = POSModalManager()

        // When
        sut.present(compactStyle: .fullScreen(title: "Card reader"), onDismiss: {}) { EmptyView() }

        // Then
        #expect(sut.compactStyle == .fullScreen(title: "Card reader"))
        #expect(sut.compactStyle?.fullScreenTitle == "Card reader")
    }

    @Test func test_dismiss_when_dialog_was_presented_then_resets_compactStyle_and_calls_onDismiss() {
        // Given
        let sut = POSModalManager()
        var onDismissCalled = false
        sut.present(compactStyle: .dialog, onDismiss: { onDismissCalled = true }) { EmptyView() }

        // When
        sut.dismiss()

        // Then
        #expect(onDismissCalled)
        #expect(sut.isPresented == false)
        #expect(sut.compactStyle == nil)
    }

    @Test func test_onDisappear_when_dialog_was_presented_then_resets_compactStyle() {
        // Given
        let sut = POSModalManager()
        sut.present(compactStyle: .dialog, onDismiss: {}) { EmptyView() }

        // When
        sut.onDisappear()

        // Then
        #expect(sut.compactStyle == nil)
        #expect(!sut.isPresented)
    }

    @Test func test_native_dismissal_when_session_changed_then_discards_the_action() async throws {
        let session = MockPOSAccessSession()
        var dismissal = POSNativePresentationDismissal()
        dismissal.presented(in: session)

        session.lock()
        try await session.signIn(withPIN: "1234")

        let action = dismissal.takeAction(in: session, action: { Issue.record("Dismissal action no longer owns this session") })
        #expect(action == nil)
    }

    @Test func test_dismiss_when_completion_is_supplied_then_calls_it_once_after_clearing_presentation() {
        // Given
        let sut = POSModalManager()
        var callbacks: [String] = []
        sut.present(compactStyle: .dialog, onDismiss: { callbacks.append("dismiss") }, onDismissCompleted: {
            #expect(!sut.isPresented)
            #expect(sut.compactStyle == nil)
            callbacks.append("completed")
        }) { EmptyView() }

        // When
        sut.dismiss()
        sut.dismiss()

        // Then
        #expect(callbacks == ["dismiss", "completed"])
    }

    @Test func test_onDisappear_when_completion_is_supplied_then_clears_it_without_reopening_content() {
        // Given
        let sut = POSModalManager()
        var completed = false
        sut.present(compactStyle: .dialog, onDismiss: {}, onDismissCompleted: { completed = true }) { EmptyView() }

        // When
        sut.onDisappear()
        sut.dismiss()

        // Then
        #expect(!completed)
    }
}
