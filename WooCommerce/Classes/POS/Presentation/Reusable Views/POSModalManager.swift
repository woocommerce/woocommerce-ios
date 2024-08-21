import SwiftUI

class POSModalManager: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var modalContent: AnyView = AnyView(EmptyView())

    func present<Content: View>(_ content: Content) {
        self.modalContent = AnyView(content)
        self.isPresented = true
    }

    func dismiss() {
        self.isPresented = false
    }
}
