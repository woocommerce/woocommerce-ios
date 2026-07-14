import SwiftUI

public extension View {
    /// Presents a tooltip anchored to this view while `isPresented` is `true`.
    ///
    /// The tooltip is hosted in a window above the app, so it is never clipped by a scroll view,
    /// navigation bar, or other container the anchor lives in; it tracks the anchor as it scrolls
    /// and hides itself while the anchor is off screen. It is non-modal: it does not block the rest
    /// of the UI. Tapping it dismisses it; showing it — and any other dismissal (on navigation,
    /// scroll, etc.) — is the caller's job through `isPresented`. The presenter positions the bubble
    /// so it stays on screen, with the arrow pointing at this view's center. Pass
    /// `preferredPlacement` to request a side; it is honored unless that side lacks room, in which
    /// case the presenter flips to the opposite side.
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
