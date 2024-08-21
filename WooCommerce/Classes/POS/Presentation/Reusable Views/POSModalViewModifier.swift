import SwiftUI

struct POSRootModalViewModifier: ViewModifier {
    @EnvironmentObject var modalManager: POSModalManager

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: modalManager.isPresented ? 3 : 0)
                .disabled(modalManager.isPresented)

            if modalManager.isPresented {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)

                modalManager.modalContent
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .transition(.scale)
                    .zIndex(1)
                    .padding()
            }
        }
    }
}

extension View {
    /// This should be applied at the root Point of Sale view only. It provides the styling for all POSModals. Nothing will show with this view alone.
    /// Ensure you've injected a `POSModalManager` environment object to the view you use this on.
    ///
    /// Trigger POS modal presentation using the `posModal` modifier
    ///
    /// - Returns: a view that displays modal content over the Point of Sale, when instructed to by child views using the `posModal` modifier
    func posRootModal() -> some View {
        self.modifier(POSRootModalViewModifier())
    }
}

struct POSModalViewModifier<ModalContent: View>: ViewModifier {
    @EnvironmentObject var modalManager: POSModalManager
    @Binding var isPresented: Bool
    @ViewBuilder let modalContent: () -> ModalContent

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    modalManager.present(modalContent())
                } else {
                    modalManager.dismiss()
                }
            }
    }
}

extension View {
    /// Shows a modal view over the Point of Sale experience.
    ///
    /// The content is responsible for setting its own size – it will be presented at that size, with minimal padding around it.
    ///
    /// This will only work in a view heirarchy containing a `posRootModal` modifier.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control when the modal is shown.
    ///   - content: Content to sho
    /// - Returns: a modified view which can show the modal content specifed, when applicable.
    func posModal<ModalContent: View>(isPresented: Binding<Bool>,
                                      @ViewBuilder content: @escaping () -> ModalContent) -> some View {
        self.modifier(
            POSModalViewModifier(isPresented: isPresented,
                                 modalContent: content))
    }
}
