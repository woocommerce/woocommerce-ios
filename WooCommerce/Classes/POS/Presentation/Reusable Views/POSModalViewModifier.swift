import SwiftUI

struct POSRootModalViewModifier: ViewModifier {
    @EnvironmentObject var modalManager: POSModalManager

    private let animationDuration = Constants.animationDuration
    private let scaleTransitionAmount = Constants.scaleTransitionAmount

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: modalManager.isPresented ? 3 : 0)
                .disabled(modalManager.isPresented)
                .accessibilityElement(children: modalManager.isPresented ? .ignore : .contain)

            if modalManager.isPresented {
                Color.posOverlayFill
                    .edgesIgnoringSafeArea(.all)
                    // Don't scale/fade in the backdrop
                    .animation(nil, value: modalManager.isPresented)
                ZStack {
                    modalManager.getContent()
                        .background(Color.posPrimaryBackground)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 8)
                        .padding()
                }
                .zIndex(1)
                // Scale the modal container in and out, fading appropriately.
                // Unfortunately combined doesn't work on removal.
                // The extra ZStack prevents changing modalContent from scaling and fading, but the ZIndex needs to be
                // consistent even when animating out, which it wouldn't be if unspecified.
                .transition(.scale(scale: scaleTransitionAmount).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: animationDuration), value: modalManager.isPresented)
    }
}

private extension POSRootModalViewModifier {
    enum Constants {
        static let animationDuration: CGFloat = 0.25
        static let scaleTransitionAmount: CGFloat = 0.9
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

struct POSModalViewModifier<Item: Identifiable & Equatable, ModalContent: View>: ViewModifier {
    @EnvironmentObject var modalManager: POSModalManager
    @Binding var item: Item?
    let modalContent: (Item) -> ModalContent

    func body(content: Content) -> some View {
        content
            .onChange(of: item) { newItem in
                if let newItem = newItem {
                    modalManager.present {
                        modalContent(newItem)
                            .animation(.default, value: item)
                    }
                } else {
                    modalManager.dismiss()
                }
            }
    }
}

struct POSModalViewModifierForBool<ModalContent: View>: ViewModifier {
    @EnvironmentObject var modalManager: POSModalManager
    @Binding var isPresented: Bool
    let modalContent: () -> ModalContent

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    modalManager.present { modalContent() }
                } else {
                    modalManager.dismiss()
                }
            }
    }
}

extension View {
    /// Shows a modal view over the Point of Sale experience.
    ///
    /// Note that the content will not be redrawn in response to changes outside of the view builder.
    /// Use the `posModal(item: content:)` modifier to work around this limitation.
    /// The content is responsible for setting its own size – it will be presented at that size, with minimal padding around it.
    ///
    /// This will only work in a view heirarchy containing a `posRootModal` modifier.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control when the modal is shown.
    ///   - content: Content to show – note this will not update in response to changes outside the scope of the view builder
    /// - Returns: a modified view which can show the modal content specifed, when applicable.
    func posModal<ModalContent: View>(isPresented: Binding<Bool>,
                                      @ViewBuilder content: @escaping () -> ModalContent) -> some View {
        self.modifier(
            POSModalViewModifierForBool(isPresented: isPresented,
                                        modalContent: content))
    }

    /// Shows a modal view over the Point of Sale experience.
    ///
    /// The content will update when the item changes.
    /// The content is responsible for setting its own size – it will be presented at that size, with minimal padding around it.
    ///
    /// This will only work in a view heirarchy containing a `posRootModal` modifier.
    ///
    /// - Parameters:
    ///   - item: Binding to control when the modal is shown. When non-nil, the item is used to build the content.
    ///   - content: Content to show
    /// - Returns: a modified view which can show the modal content specifed, when applicable.
    func posModal<Item: Identifiable & Equatable, ModalContent: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> ModalContent) -> some View {
        self.modifier(
            POSModalViewModifier(item: item,
                                 modalContent: content))
    }
}
