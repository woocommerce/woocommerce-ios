import SwiftUI

class POSModalManager: ObservableObject {
    @Published private(set) var isPresented: Bool = false
    private var contentBuilder: (() -> AnyView)?

    func present<Content: View>(_ content: @escaping () -> Content) {
        self.contentBuilder = { AnyView(content()) }
        self.isPresented = true
    }

    func dismiss() {
        self.isPresented = false
    }

    func getContent() -> AnyView {
        contentBuilder?() ?? AnyView(EmptyView())
    }
}
