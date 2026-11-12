import SwiftUI

enum POSModalPresentationStyle: Sendable {
    case automatic
    case card
}

class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    @Published private(set) var allowsInteractiveDismissal: Bool = true
    @Published private(set) var isFullScreen: Bool = false
    @Published private(set) var presentationStyle: POSModalPresentationStyle = .automatic
    private var contentBuilder: (() -> AnyView)?
    private var onDismiss: (() -> Void)?

    func present<Content: View>(presentationStyle: POSModalPresentationStyle = .automatic,
                               onDismiss: @escaping () -> Void, content: @escaping () -> Content) {
        contentBuilder = { AnyView(content()) }
        self.onDismiss = onDismiss
        self.presentationStyle = presentationStyle
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
        presentationStyle = .automatic
    }
}
