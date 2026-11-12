import SwiftUI
import Testing
@testable import PointOfSale

@MainActor
struct POSModalManagerTests {
    @Test func test_present_when_style_is_unspecified_then_preserves_automatic_presentation() {
        // Given
        let sut = POSModalManager()

        // When
        sut.present(onDismiss: {}) { EmptyView() }

        // Then
        #expect(sut.isPresented)
        #expect(sut.presentationStyle == .automatic)
    }

    @Test func test_dismiss_when_card_is_presented_then_resets_style_and_calls_dismissal() {
        // Given
        let sut = POSModalManager()
        var dismissals = 0
        sut.present(presentationStyle: .card, onDismiss: { dismissals += 1 }) { EmptyView() }
        #expect(sut.presentationStyle == .card)

        // When
        sut.dismiss()
        sut.present(onDismiss: {}) { EmptyView() }

        // Then
        #expect(dismissals == 1)
        #expect(sut.presentationStyle == .automatic)
    }

    @Test func test_on_disappear_when_card_is_presented_then_resets_style_without_dismissal_callback() {
        // Given
        let sut = POSModalManager()
        var dismissals = 0
        sut.present(presentationStyle: .card, onDismiss: { dismissals += 1 }) { EmptyView() }

        // When
        sut.onDisappear()

        // Then
        #expect(sut.presentationStyle == .automatic)
        #expect(dismissals == 0)
    }
}
