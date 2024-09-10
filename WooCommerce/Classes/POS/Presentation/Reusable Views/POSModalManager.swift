import SwiftUI

class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    @Published var allowsInteractiveDismissal: Bool = true
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

    private func reset() {
        onDismiss = nil
        allowsInteractiveDismissal = true
        contentBuilder = nil
    }
}
