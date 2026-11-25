import SwiftUI

@MainActor
final class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    @Published private(set) var allowsInteractiveDismissal: Bool = true
    @Published private(set) var isFullScreen: Bool = false
    @Published private(set) var compactStyle: POSModalCompactStyle?
    private var owner: UUID?
    private var session: POSAccessSession?
    private var contentBuilder: (() -> AnyView)?
    private var onDismiss: (() -> Void)?
    private var onDismissCompleted: (() -> Void)?

    func present<Content: View>(compactStyle: POSModalCompactStyle,
                                owner: UUID? = nil,
                                session: POSAccessSession? = nil,
                                isCovered: Bool = false,
                                onDismiss: @escaping () -> Void,
                                onDismissCompleted: (() -> Void)? = nil,
                                content: @escaping () -> Content) {
        guard !isCovered, session?.isLocked != true || compactStyle.preservesOnLock else { return }
        self.compactStyle = compactStyle
        self.owner = owner
        self.session = session
        contentBuilder = { AnyView(content()) }
        self.onDismiss = onDismiss
        self.onDismissCompleted = onDismissCompleted
        isPresented = true
    }

    func dismiss(owner: UUID? = nil) {
        guard isPresented, owner == nil || self.owner == owner else { return }
        guard session?.isLocked != true else {
            clearPresentation()
            return
        }
        let onDismiss = self.onDismiss
        let completion = onDismissCompleted
        let session = self.session
        let scope = session?.accessScope
        let changes = {
            self.clearPresentation()
            onDismiss?()
        }
        if let completion {
            withAnimation(completionCriteria: .removed, changes) {
                if let session, let scope, !session.isCurrent(scope) { return }
                completion()
            }
        } else {
            changes()
        }
    }

    func dismissForLock() {
        guard compactStyle?.preservesOnLock != true else { return }
        clearPresentation()
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
        clearPresentation()
    }

    private func clearPresentation() {
        guard isPresented else { return }
        isPresented = false
        owner = nil
        session = nil
        onDismiss = nil
        onDismissCompleted = nil
        allowsInteractiveDismissal = true
        isFullScreen = false
        compactStyle = nil
        contentBuilder = nil
    }
}
