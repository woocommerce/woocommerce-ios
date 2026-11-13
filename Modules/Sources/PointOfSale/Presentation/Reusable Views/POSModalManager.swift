import SwiftUI

@MainActor
final class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    @Published private(set) var allowsInteractiveDismissal: Bool = true
    @Published private(set) var isFullScreen: Bool = false
    private var contentBuilder: (() -> AnyView)?
    private var onDismiss: (() -> Void)?
    private var dismissesOnLock = true

    func present<Content: View>(dismissOnLock: Bool = true, onDismiss: @escaping () -> Void, content: @escaping () -> Content) {
        contentBuilder = { AnyView(content()) }
        dismissesOnLock = dismissOnLock
        self.onDismiss = onDismiss
        isPresented = true
    }

    func dismiss() {
        onDismiss?()
        isPresented = false
        reset()
    }

    /// Lock removes presentation only; user-dismiss callbacks can cancel an active payment flow.
    func dismissForLock() {
        guard dismissesOnLock else { return }
        isPresented = false
        reset()
    }

    func getContent() -> AnyView {
        contentBuilder?() ?? AnyView(EmptyView())
    }

    func setInteractiveDismissal(_ allowed: Bool) {
        allowsInteractiveDismissal = allowed
    }

    func setFullScreen(_ fullScreen: Bool) {
        isFullScreen = fullScreen
    }

    func onDisappear() {
        isPresented = false
        reset()
    }

    private func reset() {
        dismissesOnLock = true
        onDismiss = nil
        allowsInteractiveDismissal = true
        isFullScreen = false
        contentBuilder = nil
    }
}
