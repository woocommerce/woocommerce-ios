import SwiftUI

class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    @Published private(set) var allowsInteractiveDismissal: Bool = true
    @Published private(set) var isFullScreen: Bool = false
    private var contentBuilder: (() -> AnyView)?
    private var onDismiss: (() -> Void)?

    func present<Content: View>(onDismiss: @escaping () -> Void, content: @escaping () -> Content) {
        contentBuilder = { AnyView(content()) }
        self.onDismiss = onDismiss
        isPresented = true
    }

    func dismiss() {
        onDismiss?()
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
        reset()
    }

    private func reset() {
        onDismiss = nil
        allowsInteractiveDismissal = true
        isFullScreen = false
        contentBuilder = nil
    }
}
