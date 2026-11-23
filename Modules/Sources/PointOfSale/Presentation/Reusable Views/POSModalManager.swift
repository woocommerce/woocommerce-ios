import SwiftUI

@MainActor
final class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    @Published private(set) var allowsInteractiveDismissal: Bool = true
    @Published private(set) var isFullScreen: Bool = false
    @Published private(set) var compactStyle: POSModalCompactStyle?
    private var owner: UUID?
    private var session: POSAccessSession?
    private var preservesOnLock: () -> Bool = { false }
    private var contentBuilder: (() -> AnyView)?
    private var onDismiss: (() -> Void)?
    private var onDismissCompleted: (() -> Void)?

    func present<Content: View>(compactStyle: POSModalCompactStyle,
                                owner: UUID? = nil,
                                session: POSAccessSession? = nil,
                                isCovered: Bool = false,
                                preservesOnLock: @escaping () -> Bool = { false },
                                onDismiss: @escaping () -> Void,
                                onDismissCompleted: (() -> Void)? = nil,
                                content: @escaping () -> Content) {
        guard !isCovered, session?.isLocked != true || preservesOnLock() else { return }
        self.compactStyle = compactStyle
        self.owner = owner
        self.session = session
        self.preservesOnLock = preservesOnLock
        contentBuilder = { AnyView(content()) }
        self.onDismiss = onDismiss
        self.onDismissCompleted = onDismissCompleted
        isPresented = true
    }

    func dismiss(owner: UUID? = nil, runsCallbacks: Bool = true) {
        guard isPresented, owner == nil || self.owner == owner else { return }
        let canRunCallbacks = runsCallbacks && session?.isLocked != true
        let onDismiss = canRunCallbacks ? self.onDismiss : nil
        let completion = canRunCallbacks ? self.onDismissCompleted : nil
        let session = self.session
        let scope = session?.accessScope
        let changes = {
            self.isPresented = false
            self.reset()
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
        guard !preservesOnLock() else { return }
        dismiss(runsCallbacks: false)
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
        dismiss(runsCallbacks: false)
    }

    private func reset() {
        owner = nil
        session = nil
        preservesOnLock = { false }
        onDismiss = nil
        onDismissCompleted = nil
        allowsInteractiveDismissal = true
        isFullScreen = false
        compactStyle = nil
        contentBuilder = nil
    }
}
