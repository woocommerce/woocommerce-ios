import SwiftUI

struct ModalOverlay<OverlayContent: View>: View {
    @Binding var isPresented: Bool
    @ViewBuilder let content: () -> OverlayContent
    let onDismiss: (() -> Void)?

    /// We use an internal copy of the `isPresented` state so that we can detect changes, and wrap them in a `withAnimation` call.
    /// Without this, the fade and slide animations do not work.
    @State private var internalIsPresented: Bool

    init(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, content: @escaping () -> OverlayContent) {
        self.content = content
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        self.internalIsPresented = isPresented.wrappedValue
    }

    var body: some View {
        ZStack {
            if internalIsPresented {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        dismiss()
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.1), value: internalIsPresented)

                GeometryReader { geometry in
                    VStack {
                        content()
                            .padding(16)
                            .frame(width: geometry.size.width * 0.75)
                            .frame(maxHeight: geometry.size.height * 0.8)
                            .fixedSize(horizontal: false, vertical: true) // these three modifiers define the container size
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Ensures the container is centred
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.25), value: internalIsPresented)
            }
        }
        .onChange(of: isPresented) { newValue in
            withAnimation {
                internalIsPresented = newValue
            }

            if newValue == false {
                onDismiss?()
            }
        }
    }

    private func dismiss() {
        isPresented = false
    }
}

extension View {
    func modalOverlay<OverlayContent: View>(isPresented: Binding<Bool>, @ViewBuilder overlayContent: @escaping () -> OverlayContent) -> some View {
        self.modifier(ModalOverlayModifier(isPresented: isPresented, overlayContent: overlayContent))
    }
}

struct ModalOverlayModifier<OverlayContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder let overlayContent: () -> OverlayContent

    func body(content: Content) -> some View {
        ZStack {
            // Underlying content
            content
            // Modal overlay
            ModalOverlay(isPresented: $isPresented, content: overlayContent)
        }
    }
}

/// This wrapper exists to avoid the need to init a Binding in UIKit (which we can't) but
/// retain the presentation/dismiss behaviour
struct ModalOverlay_UIKit<OverlayContent: View>: View {
    @State var isPresented: Bool = true
    @ViewBuilder let content: () -> OverlayContent
    let onDismiss: (() -> Void)?

    init(onDismiss: (() -> Void)? = nil, content: @escaping () -> OverlayContent) {
        self.content = content
        self.onDismiss = onDismiss
    }

    var body: some View {
        ModalOverlay(isPresented: $isPresented,
                     onDismiss: onDismiss,
                     content: content)
    }
}
