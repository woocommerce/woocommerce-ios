import SwiftUI
import UIKit

public extension View {
    /// Presents a ``StoreTooltip`` anchored to this view while `isPresented` is `true`.
    ///
    /// The tooltip is non-modal: it does not block the rest of the UI. Tapping the tooltip dismisses
    /// it; showing it — and any other dismissal (on navigation, scroll, etc.) — is the caller's job
    /// through `isPresented`. The presenter measures where this view sits on screen and chooses the
    /// placement so the bubble stays on screen, aiming the arrow at this view's center. Pass
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

    /// The anchor's frame in global space, kept current so placement is ready before presentation.
    @State private var anchorFrame: CGRect = .zero
    /// The rendered bubble size, used to offset the tooltip fully onto its chosen side.
    @State private var bubbleSize: CGSize = .zero

    func body(content: Content) -> some View {
        let layout = TooltipLayout(anchorFrame: anchorFrame, bounds: Self.presentationBounds)
        let arrow = layout.resolvedArrow(preferred: preferredPlacement?.arrow, bubbleSize: bubbleSize)
        // `idealWidth` + `fixedSize` makes the bubble hug its content but wrap once it would exceed the
        // room available on the chosen side, instead of laying the message out on one runaway line.
        let bubbleWidth = layout.availableBubbleWidth(for: arrow)
        return content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: AnchorFrameKey.self, value: proxy.frame(in: .global))
                }
            )
            .onPreferenceChange(AnchorFrameKey.self) { anchorFrame = $0 }
            .overlay {
                if isPresented {
                    StoreTooltip(title, message: message, arrow: arrow)
                        .frame(idealWidth: bubbleWidth)
                        .fixedSize()
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(key: BubbleSizeKey.self, value: proxy.size)
                            }
                        )
                        .onPreferenceChange(BubbleSizeKey.self) { bubbleSize = $0 }
                        // Centered on the anchor, then pushed fully onto the arrow's side.
                        .offset(layout.bubbleOffset(for: arrow, bubbleSize: bubbleSize))
                        .opacity(bubbleSize == .zero ? 0 : 1)
                        .contentShape(Rectangle())
                        .onTapGesture { isPresented = false }
                        // The bubble is offset well outside the (small) anchor overlay; without a
                        // larger container its hit area would be clipped to the anchor. This frame
                        // makes the offset bubble tappable while its empty area stays pass-through
                        // (no content shape), so the tooltip is non-modal.
                        .frame(width: Constants.hitTestExtent, height: Constants.hitTestExtent)
                }
            }
    }

    /// The window the tooltip is presented in (falling back to the main screen). Using the window
    /// rather than the screen keeps placement correct in Split View / multi-window, where the app
    /// occupies only part of the screen. A non-full-screen modal on iPad can still differ from the
    /// `.global` space the anchor is measured in; making that exact would need container-level hosting.
    private static var presentationBounds: CGRect {
        let windowSize = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .bounds.size
        return CGRect(origin: .zero, size: windowSize ?? UIScreen.main.bounds.size)
    }
}

private struct AnchorFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

private struct BubbleSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

private enum Constants {
    /// Large enough that the offset bubble always falls inside its overlay's hit-test area, on any device.
    static let hitTestExtent: CGFloat = 5000
}
