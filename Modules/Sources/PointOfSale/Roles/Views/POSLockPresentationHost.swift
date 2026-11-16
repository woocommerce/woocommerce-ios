import SwiftUI
import UIKit
import Observation

struct POSLockPresentationHost<LockContent: View>: UIViewControllerRepresentable {
    let session: POSAccessSession
    let lockContent: LockContent

    func makeCoordinator() -> POSLockPresentationCoordinator {
        POSLockPresentationCoordinator()
    }

    func makeUIViewController(context: Context) -> POSLockPresentationController {
        let controller = POSLockPresentationController()
        controller.windowFinder.onWindowChanged = { [weak controller, weak coordinator = context.coordinator] window in
            if let window {
                controller?.sourceWindow = window
                coordinator?.attach(to: window)
            }
        }
        controller.onDismiss = { [weak coordinator = context.coordinator] in
            coordinator?.detach()
        }
        return controller
    }

    func updateUIViewController(_ controller: POSLockPresentationController, context: Context) {
        let environment = context.environment
        // Do not copy the source's disabled/accessibility-hidden environment into the PIN UI.
        let content = lockContent
            .environment(\.posLayoutScale, environment.posLayoutScale)
            .environment(\.horizontalSizeClass, environment.horizontalSizeClass)
            .environment(\.dynamicTypeSize, environment.dynamicTypeSize)
            .environment(\.colorScheme, environment.colorScheme)
            .environment(\.layoutDirection, environment.layoutDirection)
        context.coordinator.update(session: session, content: AnyView(content))
    }

    static func dismantleUIViewController(_ controller: POSLockPresentationController, coordinator: POSLockPresentationCoordinator) {
        controller.windowFinder.onWindowChanged = nil
        controller.onDismiss = nil
        coordinator.detach()
    }
}

final class POSLockPresentationController: UIViewController {
    let windowFinder = WindowFinderView()
    weak var sourceWindow: UIWindow?
    var onDismiss: (() -> Void)?

    override func loadView() {
        windowFinder.isUserInteractionEnabled = false
        view = windowFinder
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // A covering controller may hide POS; dismissal or a detached root ends its ownership.
        var controller: UIViewController? = self
        while let current = controller {
            if current.isBeingDismissed ||
                (current.parent == nil && current.presentingViewController == nil &&
                 current.viewIfLoaded?.window == nil && sourceWindow?.rootViewController !== current) {
                onDismiss?()
                return
            }
            controller = current.parent
        }
    }
}

@MainActor
final class POSLockPresentationCoordinator: NSObject {
    private weak var sourceWindow: UIWindow?
    private weak var previousKeyWindow: UIWindow?
    private var lockWindow: UIWindow?
    private var sourceAccessibilityHidden = false
    private var session: POSAccessSession?
    private var observationID = UUID()
    private var content = AnyView(EmptyView())
    private var synchronizationTask: Task<Void, Never>?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(sceneActivated), name: UIScene.didActivateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneDisconnected), name: UIScene.didDisconnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sourceBecameKey), name: UIWindow.didBecomeKeyNotification, object: nil)
    }

    func attach(to window: UIWindow) {
        if sourceWindow !== window {
            removeLock()
            sourceWindow = window
        }
        synchronize()
    }

    func update(session: POSAccessSession, content: AnyView) {
        let sessionChanged = self.session !== session
        self.session = session
        self.content = content
        if sessionChanged {
            synchronizationTask?.cancel()
            observeLock()
        }
        synchronize()
    }

    private func observeLock() {
        guard let session else { return }
        let observationID = UUID()
        self.observationID = observationID
        // Native full-screen controllers can detach SwiftUI; observe lock independently of that subtree.
        withObservationTracking {
            _ = session.isLocked
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.observationID == observationID else { return }
                self.synchronize()
                self.observeLock()
            }
        }
    }

    func detach() {
        synchronizationTask?.cancel()
        synchronizationTask = nil
        removeLock()
        sourceWindow = nil
        session = nil
        content = AnyView(EmptyView())
        observationID = UUID()
        NotificationCenter.default.removeObserver(self)
    }

    private func synchronize() {
        synchronizationTask?.cancel()
        // Window focus can change SwiftUI state; wait until the representable update returns.
        synchronizationTask = Task { @MainActor [weak self] in
            guard !Task.isCancelled else { return }
            self?.synchronizeWindow()
        }
    }

    private func synchronizeWindow() {
        guard session?.isLocked == true, let sourceWindow, let scene = sourceWindow.windowScene,
              scene.activationState != .unattached else {
            removeLock()
            return
        }
        sourceWindow.endEditing(true)
        if let hostingController = lockWindow?.rootViewController as? UIHostingController<AnyView> {
            hostingController.rootView = content
            lockWindow?.frame = sourceWindow.frame
            if sourceWindow.isKeyWindow {
                lockWindow?.makeKey()
            }
            return
        }
        previousKeyWindow = scene.keyWindow
        sourceAccessibilityHidden = sourceWindow.accessibilityElementsHidden
        sourceWindow.accessibilityElementsHidden = true
        let controller = UIHostingController(rootView: content)
        controller.view.backgroundColor = UIColor(Color.posSurfaceContainerLow)
        controller.view.accessibilityViewIsModal = true
        let window = UIWindow(windowScene: scene)
        window.frame = sourceWindow.frame
        // Only outrank this scene's POS window, without competing with system authorization UI.
        window.windowLevel = UIWindow.Level(rawValue: sourceWindow.windowLevel.rawValue + 1)
        window.accessibilityIdentifier = "pos-lock-window"
        window.rootViewController = controller
        lockWindow = window
        window.makeKeyAndVisible()
    }

    private func removeLock() {
        guard let window = lockWindow else { return }
        let wasKey = window.isKeyWindow
        let scene = window.windowScene
        lockWindow = nil
        sourceWindow?.accessibilityElementsHidden = sourceAccessibilityHidden
        window.isHidden = true
        window.rootViewController = nil
        window.windowScene = nil
        if wasKey, let scene, scene.activationState != .unattached {
            let target = previousKeyWindow.flatMap { !$0.isHidden && $0.windowScene === scene ? $0 : nil } ?? sourceWindow
            if let target, !target.isHidden, target.windowScene === scene {
                target.makeKey()
            }
        }
        previousKeyWindow = nil
    }

    @objc private func sourceBecameKey(_ notification: Notification) {
        guard notification.object as? UIWindow === sourceWindow, lockWindow != nil else { return }
        synchronize()
    }

    @objc private func sceneActivated(_ notification: Notification) {
        guard notification.object as? UIWindowScene === sourceWindow?.windowScene else { return }
        synchronize()
    }

    @objc private func sceneDisconnected(_ notification: Notification) {
        guard notification.object as? UIWindowScene === sourceWindow?.windowScene else { return }
        synchronizationTask?.cancel()
        removeLock()
    }
}
