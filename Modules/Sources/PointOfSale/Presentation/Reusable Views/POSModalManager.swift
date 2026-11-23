import SwiftUI

class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    @Published private(set) var allowsInteractiveDismissal: Bool = true
    @Published private(set) var isFullScreen: Bool = false
    @Published private(set) var compactStyle: POSModalCompactStyle?
    private var contentBuilder: (() -> AnyView)?
    private var onDismiss: (() -> Void)?
    private var onDismissCompleted: (() -> Void)?

    func present<Content: View>(compactStyle: POSModalCompactStyle,
                                onDismiss: @escaping () -> Void,
                                onDismissCompleted: (() -> Void)? = nil,
                                content: @escaping () -> Content) {
        self.compactStyle = compactStyle
        contentBuilder = { AnyView(content()) }
        self.onDismiss = onDismiss
        self.onDismissCompleted = onDismissCompleted
        isPresented = true
    }

    func dismiss() {
        let changes = {
            self.onDismiss?()
            self.isPresented = false
            self.reset()
        }
        if let onDismissCompleted {
            withAnimation(completionCriteria: .removed, changes, completion: onDismissCompleted)
        } else {
            changes()
        }
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
        onDismissCompleted = nil
        allowsInteractiveDismissal = true
        isFullScreen = false
        compactStyle = nil
        contentBuilder = nil
    }
}
