import SwiftUI
import Combine

class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    @Published private(set) var allowsInteractiveDismissal: Bool = true
    private var contentBuilder: (() -> AnyView)?
    private var onDismiss: (() -> Void)?
    private var subscriptions = Set<AnyCancellable>()

    func present<Content: View>(onDismiss: @escaping () -> Void, content: @escaping () -> Content) {
        contentBuilder = { AnyView(content()) }
        self.onDismiss = onDismiss
        isPresented = true

        $isPresented
            .sink { [weak self] _ in
                guard let self else { return }
                if !isPresented {
                    reset()
                }
            }
            .store(in: &subscriptions)
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

    func onDisappear() {
        reset()
    }

    private func reset() {
        onDismiss = nil
        allowsInteractiveDismissal = true
        contentBuilder = nil
        subscriptions = Set()
    }
}
