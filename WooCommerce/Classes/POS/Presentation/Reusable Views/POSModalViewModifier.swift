import SwiftUI

struct POSModalViewModifier<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let modalContent: () -> ModalContent

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isPresented ? 3 : 0)
                .disabled(isPresented)

            if isPresented {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)

                modalContent()
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
    func posModal<ModalContent: View>(isPresented: Binding<Bool>,
                                      fixedWidth: Bool = true,
                                      fixedHeight: Bool = true,
                                      @ViewBuilder content: @escaping () -> ModalContent) -> some View {
        self.modifier(
            POSModalViewModifier(isPresented: isPresented,
                                 modalContent: content))
    }
}
