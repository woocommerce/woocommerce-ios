import SwiftUI

class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    @Published var allowsInteractiveDismissal: Bool = true
    private var contentBuilder: (() -> AnyView)?
    private var onDismiss: (() -> Void)?

    func present<Content: View>(onDismiss: @escaping () -> Void, content: @escaping () -> Content) {
        self.contentBuilder = { AnyView(content()) }
        self.onDismiss = onDismiss
        self.isPresented = true
    }

    func dismiss() {
        self.isPresented = false
        self.onDismiss?()
        self.allowsInteractiveDismissal = true
        self.onDismiss = nil
        self.contentBuilder = nil
    }

    func getContent() -> AnyView {
        contentBuilder?() ?? AnyView(EmptyView())
    }

    func setInteractiveDismissal(_ allowed: Bool) {
        allowsInteractiveDismissal = allowed
    }
}
