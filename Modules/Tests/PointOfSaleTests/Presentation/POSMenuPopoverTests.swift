import SwiftUI
import Testing
@testable import PointOfSale

@MainActor
@Suite(.serialized, .timeLimit(.minutes(5)))
final class POSMenuPopoverTests {
    private var window: UIWindow?

    @Test func test_update_when_menu_is_closed_then_does_not_build_content() {
        // Given
        let state = MenuState(isPresented: false)
        let pointer = Binding.constant(POSMenuPointer())
        let sut = POSMenuPopover<EmptyView>.Coordinator(isPresented: state.presentation, pointer: pointer, metrics: .regular)
        var contentBuilds = 0

        // When
        sut.update(anchor: UIViewController(), content: {
            contentBuilds += 1
            return EmptyView()
        }, isPresented: state.presentation, pointer: pointer, metrics: .regular)

        // Then
        #expect(contentBuilds == 0)
        #expect(!state.isPresented)
    }

    @Test func test_update_when_anchor_has_no_window_then_cancels_pending_presentation() async {
        // Given
        let state = MenuState(isPresented: true)
        let pointer = Binding.constant(POSMenuPointer())
        let sut = POSMenuPopover<EmptyView>.Coordinator(isPresented: state.presentation, pointer: pointer, metrics: .regular)
        let anchor = UIViewController()
        var contentBuilds = 0
        defer { withExtendedLifetime(sut) {} }

        // When
        await withCheckedContinuation { continuation in
            state.onDismiss = { continuation.resume() }
            sut.update(anchor: anchor, content: {
                contentBuilds += 1
                return EmptyView()
            }, isPresented: state.presentation, pointer: pointer, metrics: .regular)
        }

        // Then
        #expect(!state.isPresented)
        #expect(contentBuilds == 0)
    }

    @Test func test_update_when_presentation_is_refused_then_resets_and_allows_retry() async {
        // Given
        let state = MenuState(isPresented: true)
        let pointer = Binding.constant(POSMenuPointer())
        let sut = POSMenuPopover<EmptyView>.Coordinator(isPresented: state.presentation, pointer: pointer, metrics: .regular)
        let anchor = RefusingPresenter()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        window?.rootViewController = anchor
        window?.isHidden = false
        defer {
            window?.isHidden = true
            window = nil
            withExtendedLifetime(sut) {}
        }

        // When
        for _ in 0..<2 {
            state.isPresented = true
            await withCheckedContinuation { continuation in
                state.onDismiss = { continuation.resume() }
                sut.update(anchor: anchor, content: { EmptyView() }, isPresented: state.presentation, pointer: pointer, metrics: .regular)
            }
        }

        // Then
        #expect(!state.isPresented)
        #expect(anchor.presentationAttempts == 2)
    }
}

@MainActor
private final class RefusingPresenter: UIViewController {
    private(set) var presentationAttempts = 0

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentationAttempts += 1
    }
}

@MainActor
private final class MenuState {
    var isPresented: Bool
    var onDismiss: (() -> Void)?

    init(isPresented: Bool) {
        self.isPresented = isPresented
    }

    var presentation: Binding<Bool> {
        Binding(get: { self.isPresented }, set: { value in
            self.isPresented = value
            if !value {
                let onDismiss = self.onDismiss
                self.onDismiss = nil
                onDismiss?()
            }
        })
    }
}
