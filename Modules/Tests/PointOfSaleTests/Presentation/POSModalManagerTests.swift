import SwiftUI
import Testing
@testable import PointOfSale

@MainActor
struct POSModalManagerTests {
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

    @Test func test_onDisappear_when_dialog_was_presented_then_clears_presentation_without_dismissal_callbacks() {
        // Given
        let sut = POSModalManager()
        var onDismissCalled = false
        sut.present(compactStyle: .dialog, onDismiss: { onDismissCalled = true }) { EmptyView() }

        // When
        sut.onDisappear()

        // Then
        #expect(!sut.isPresented)
        #expect(sut.compactStyle == nil)
        #expect(!onDismissCalled)
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
