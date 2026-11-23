import SwiftUI

class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    @Published private(set) var allowsInteractiveDismissal: Bool = true
    @Published private(set) var isFullScreen: Bool = false
    @Published private(set) var compactStyle: POSModalCompactStyle?
    private var owner: UUID?
    private var preservesOnLock: () -> Bool = { false }
    private var contentBuilder: (() -> AnyView)?
    private var onDismiss: (() -> Void)?
    private var onDismissCompleted: (() -> Void)?

    func present<Content: View>(compactStyle: POSModalCompactStyle,
                                owner: UUID? = nil,
                                preservesOnLock: @escaping () -> Bool = { false },
                                onDismiss: @escaping () -> Void,
                                onDismissCompleted: (() -> Void)? = nil,
                                content: @escaping () -> Content) {
        self.compactStyle = compactStyle
        self.owner = owner
        self.preservesOnLock = preservesOnLock
        contentBuilder = { AnyView(content()) }
        self.onDismiss = onDismiss
        self.onDismissCompleted = onDismissCompleted
        isPresented = true
    }

    func dismiss(owner: UUID? = nil, runsCallbacks: Bool = true) {
        guard isPresented, owner == nil || self.owner == owner else { return }
        let onDismiss = runsCallbacks ? self.onDismiss : nil
        let onDismissCompleted = runsCallbacks ? self.onDismissCompleted : nil
        let changes = {
            self.isPresented = false
            self.reset()
            onDismiss?()
        }
        if let onDismissCompleted {
            withAnimation(completionCriteria: .removed, changes, completion: onDismissCompleted)
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
        preservesOnLock = { false }
        onDismiss = nil
        onDismissCompleted = nil
        allowsInteractiveDismissal = true
        isFullScreen = false
        compactStyle = nil
        contentBuilder = nil
    }
}
