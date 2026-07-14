import SwiftUI

public extension View {
    /// Presents a tooltip anchored to this view while `isPresented` is `true`.
    ///
    /// The tooltip is non-modal, shows in a window above the app (so nothing clips it), and stays
    /// on screen with the arrow pointing at this view. Tapping it dismisses it; showing it is the
    /// caller's job through `isPresented`. `preferredPlacement` requests a side, flipped only when
    /// that side lacks room.
    func storeTooltip(isPresented: Binding<Bool>,
                      preferredPlacement: StoreTooltipPlacement? = nil,
                      title: String,
                      message: String? = nil) -> some View {
        modifier(StoreTooltipPresentationModifier(isPresented: isPresented,
                                                  preferredPlacement: preferredPlacement,
                                                  title: title,
                                                  message: message))
    }
}

private struct StoreTooltipPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let preferredPlacement: StoreTooltipPlacement?
    let title: String
    let message: String?

    /// The anchor's frame in global space, kept current so placement follows the anchor as it moves.
    @State private var anchorFrame: CGRect = .zero
    /// Stable identity for this presentation, so the shared window presenter can tell tooltips apart.
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frame in
                anchorFrame = frame
                if isPresented {
                    show()
                }
            }
            .onChange(of: isPresented) { _, presented in
                if presented {
                    show()
                } else {
                    TooltipPresenter.shared.dismiss(id: id)
                }
            }
            .onAppear {
                if isPresented {
                    show()
                }
            }
            .onDisappear {
                // Fully dismiss when the anchor leaves the hierarchy (e.g. navigation): reset the
                // caller's binding too, so returning to this screen doesn't silently re-present it.
                if isPresented {
                    isPresented = false
                }
                TooltipPresenter.shared.dismiss(id: id)
            }
    }

    private func show() {
        TooltipPresenter.shared.show(TooltipRequest(id: id,
                                                    title: title,
                                                    message: message,
                                                    preferredPlacement: preferredPlacement,
                                                    anchorFrame: anchorFrame),
                                     onDismiss: { isPresented = false })
    }
}
