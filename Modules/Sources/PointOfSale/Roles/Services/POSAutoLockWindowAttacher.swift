import SwiftUI
import UIKit

/// Bridges the auto-lock controller into a UIWindow-level gesture observer so taps inside
/// POS sheets and full-screen covers reset the inactivity timer too. The dashboard-level
/// SwiftUI gesture only sees touches on its own view tree.
struct POSAutoLockWindowAttacher: UIViewRepresentable {
    let controller: POSAutoLockActivityController?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WindowFinderView {
        let view = WindowFinderView()
        view.isUserInteractionEnabled = false
        let coordinator = context.coordinator
        view.onWindowChanged = { [weak coordinator] window in
            coordinator?.sync(window: window)
        }
        return view
    }

    func updateUIView(_ uiView: WindowFinderView, context: Context) {
        context.coordinator.controller = controller
        context.coordinator.sync(window: uiView.window)
    }

    static func dismantleUIView(_ uiView: WindowFinderView, coordinator: Coordinator) {
        coordinator.detach()
    }

    @MainActor
    final class Coordinator {
        var controller: POSAutoLockActivityController?
        private weak var attachedWindow: UIWindow?
        private var recognizer: POSActivityGestureRecognizer?

        func sync(window: UIWindow?) {
            guard let window, let controller else {
                detach()
                return
            }
            guard attachedWindow !== window else { return }
            detach()
            let new = POSActivityGestureRecognizer { [weak controller] in
                controller?.noteActivityThrottled()
            }
            window.addGestureRecognizer(new)
            attachedWindow = window
            recognizer = new
        }

        func detach() {
            if let window = attachedWindow, let recognizer {
                window.removeGestureRecognizer(recognizer)
            }
            attachedWindow = nil
            recognizer = nil
        }
    }
}

/// UIView whose only job is to surface its UIWindow up to SwiftUI via `didMoveToWindow`.
final class WindowFinderView: UIView {
    var onWindowChanged: ((UIWindow?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChanged?(window)
    }
}

/// UIGestureRecognizer that observes every touch on the window without competing for it.
/// Fires `onActivity` on touchesBegan and immediately fails so other recognizers proceed
/// normally.
final class POSActivityGestureRecognizer: UIGestureRecognizer {
    private let onActivity: () -> Void

    init(onActivity: @escaping () -> Void) {
        self.onActivity = onActivity
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        onActivity()
        state = .failed
    }
}
