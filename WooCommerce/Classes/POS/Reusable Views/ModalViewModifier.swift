import SwiftUI

struct ModalViewModifier<Item: Identifiable, ModalContent: View>: ViewModifier {
    @Binding var item: Item?
    let modalContent: (Item) -> ModalContent

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: item != nil ? 3 : 0)
                .disabled(item != nil)

            if let item = item {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)

                modalContent(item)
                    .frame(width: 300, height: 400)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .transition(.scale)
                    .zIndex(1)
                    .padding()
            }
        }
    }
}

extension View {
    func modal<Item: Identifiable, ModalContent: View>(
        item: Binding<Item?>,
        @ViewBuilder modalContent: @escaping (Item) -> ModalContent
    ) -> some View {
        self.modifier(ModalViewModifier(item: item, modalContent: modalContent))
    }
}
