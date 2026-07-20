import SwiftUI
import UIKit

/// What a `storeTooltip` modifier asks the presenter to show.
struct TooltipRequest: Equatable {
    let id: UUID
    let title: String
    let message: String?
    let preferredPlacement: StoreTooltipPlacement?
    /// The anchor's frame in global/window space.
    let anchorFrame: CGRect

    static let empty = TooltipRequest(id: UUID(), title: "", message: nil, preferredPlacement: nil, anchorFrame: .zero)
}

/// Hosts a ``StoreTooltip`` in a dedicated pass-through window above the app, so no scroll view,
/// navigation bar, or other container of the anchor clips it. Placement comes from ``TooltipLayout``
/// in global coordinates; only one tooltip shows at a time — the most recent presenter wins.
@MainActor
final class TooltipPresenter {
    static let shared = TooltipPresenter()

    private let model = TooltipOverlayModel()
    private var window: PassthroughWindow?
    /// Identifies the presentation currently owning the window, so a stale modifier can't tear down
    /// a tooltip another one has since taken over.
    private var activeID: UUID?

    private init() {}

    /// Shows — or, for the active presentation, updates — the tooltip for the request's `id`,
    /// claiming the shared window from any other presentation (whose caller's binding is reset via
    /// its `onDismiss` first, so it isn't left stuck "presented" but invisible). `onDismiss` is
    /// invoked when the user taps the bubble.
    func show(_ request: TooltipRequest, onDismiss: @escaping () -> Void) {
        if let activeID, activeID != request.id {
            model.onDismiss()
        }
        activeID = request.id
        model.request = request
        model.onDismiss = onDismiss
        model.isPresented = true
        showWindow()
    }

    /// Hides the tooltip if `id` still owns the window; a no-op for a superseded presentation. The
    /// window itself is kept (hidden) and reused by the next presentation.
    func dismiss(id: UUID) {
        guard activeID == id else { return }
        activeID = nil
        model.isPresented = false
        model.onDismiss = {}
        // Clear the hit region so a tap can't land on a stale bubble frame before the next render.
        model.bubbleFrame = .zero
        window?.isHidden = true
    }

    private func showWindow() {
        guard let scene = Self.activeScene, let appFrame = scene.keyWindow?.frame else { return }
        if window == nil {
            let window = PassthroughWindow(windowScene: scene)
            window.windowLevel = .normal + 1
            window.backgroundColor = .clear
            // Only forward touches that land on the bubble while its anchor is on screen; everything
            // else falls through to the app, which is what keeps the tooltip non-modal.
            window.isPointInsideTooltip = { [model] point, bounds in
                bounds.intersects(model.request.anchorFrame) && model.bubbleFrame.contains(point)
            }
            let host = UIHostingController(rootView: TooltipOverlayRootView(model: model))
            host.view.backgroundColor = .clear
            window.rootViewController = host
            self.window = window
        }
        // Match the app's window — re-applied on every update, which covers rotation and Split View
        // resizes — so the overlay's coordinate space lines up with the anchor's global frame.
        window?.frame = appFrame
        window?.isHidden = false
    }

    private static var activeScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}

/// State shared between the presenter and the hosted overlay view. The request is pushed by the
/// presenter; `bubbleFrame` is reported back by the overlay after it measures and positions the
/// bubble, and drives the window's hit-testing.
@MainActor
@Observable
final class TooltipOverlayModel {
    var isPresented = false
    var request: TooltipRequest = .empty
    /// The rendered bubble's frame in window/global space; the window forwards touches only here.
    var bubbleFrame: CGRect = .zero
    /// Invoked when the user taps the bubble, so the presenting caller can update its binding.
    var onDismiss: () -> Void = {}
}

/// A window that only intercepts touches over the tooltip bubble, letting every other touch fall
/// through to the app beneath it — which is what keeps the tooltip non-modal.
private final class PassthroughWindow: UIWindow {
    var isPointInsideTooltip: (CGPoint, CGRect) -> Bool = { _, _ in false }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isPointInsideTooltip(point, bounds) else { return nil }
        return super.hitTest(point, with: event)
    }
}

/// Renders the bubble at the anchor's global position using ``TooltipLayout`` and reports its frame
/// back to the model for hit-testing. Tapping anywhere on the bubble dismisses the tooltip.
private struct TooltipOverlayRootView: View {
    let model: TooltipOverlayModel
    @State private var bubbleSize: CGSize = .zero
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        if model.isPresented {
            GeometryReader { proxy in
                let bounds = proxy.frame(in: .global)
                let anchorFrame = model.request.anchorFrame
                let layout = TooltipLayout(anchorFrame: anchorFrame, bounds: bounds)
                let arrowEdge = layout.resolvedArrowEdge(preferred: model.request.preferredPlacement?.arrowEdge(in: layoutDirection),
                                                         bubbleSize: bubbleSize)
                let offset = layout.bubbleOffset(for: arrowEdge, bubbleSize: bubbleSize)
                StoreTooltip(title: model.request.title,
                             message: model.request.message,
                             arrowEdge: arrowEdge,
                             arrowTip: layout.arrowTipAlongEdge(for: arrowEdge, bubbleSize: bubbleSize, bubbleOffset: offset))
                    // The title/message text hit-tests independently and would swallow the dismiss
                    // tap; the content shape below owns the whole bubble instead.
                    .allowsHitTesting(false)
                    // Measured and tappable here — on the bubble itself — because the width-cap
                    // frame below is wider than a short bubble that hugs its text, and the layout
                    // math, arrow, and tap region must all use the bubble's real frame.
                    .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frame in
                        bubbleSize = frame.size
                        model.bubbleFrame = frame
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { model.onDismiss() }
                    // `idealWidth` + `fixedSize` lets the bubble hug short text yet wrap before it
                    // would spill off the chosen side; the bubble centers in this invisible frame.
                    .frame(idealWidth: layout.availableBubbleWidth(for: arrowEdge))
                    .fixedSize()
                    // Centered on the anchor, then pushed fully onto the arrow's side (local space
                    // matches global on this full-window reader, minus its origin). `position`
                    // interprets x in the layout direction while the geometry here is absolute, so
                    // mirror it back in right-to-left layouts.
                    .position(x: layoutDirection == .rightToLeft
                                ? bounds.maxX - (anchorFrame.midX + offset.width)
                                : anchorFrame.midX + offset.width - bounds.minX,
                              y: anchorFrame.midY + offset.height - bounds.minY)
                    // Hidden until measured (so it never flashes at the pre-measurement position)
                    // and while the anchor is scrolled off screen (so it never floats over
                    // unrelated content).
                    .opacity(bubbleSize == .zero || !bounds.intersects(anchorFrame) ? 0 : 1)
            }
            .ignoresSafeArea()
        }
    }
}
