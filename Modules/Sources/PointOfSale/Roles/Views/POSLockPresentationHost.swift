import SwiftUI
import UIKit
import Observation

struct POSLockPresentationHost<LockContent: View>: UIViewRepresentable {
    let session: POSAccessSession
    let lockContent: LockContent
    var onLock: @MainActor () -> Void = {}

    func makeCoordinator() -> POSLockPresentationCoordinator { POSLockPresentationCoordinator() }

    func makeUIView(context: Context) -> WindowFinderView {
        let view = WindowFinderView()
        view.isUserInteractionEnabled = false
        view.onWindowChanged = { [weak coordinator = context.coordinator] window in
            if let window { coordinator?.attach(to: window) }
        }
        return view
    }

    func updateUIView(_ view: WindowFinderView, context: Context) {
        let environment = context.environment
        // Do not copy the source's disabled/accessibility-hidden environment into the PIN UI.
        let content = lockContent
            .environment(\.posLayoutScale, environment.posLayoutScale)
            .environment(\.horizontalSizeClass, environment.horizontalSizeClass)
            .environment(\.dynamicTypeSize, environment.dynamicTypeSize)
            .environment(\.colorScheme, environment.colorScheme)
            .environment(\.layoutDirection, environment.layoutDirection)
        context.coordinator.update(session: session, content: AnyView(content), onLock: onLock)
    }

    static func dismantleUIView(_ view: WindowFinderView, coordinator: POSLockPresentationCoordinator) {
        view.onWindowChanged = nil
        coordinator.detach()
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
    private var onLock: @MainActor () -> Void = {}
    private var handledLock = false
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

    func update(session: POSAccessSession, content: AnyView, onLock: @escaping @MainActor () -> Void = {}) {
        let sessionChanged = self.session !== session
        self.session = session
        self.content = content
        self.onLock = onLock
        if sessionChanged {
            synchronizationTask?.cancel()
            handledLock = false
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
        onLock = {}
        observationID = UUID()
        NotificationCenter.default.removeObserver(self)
    }

    private func synchronize() {
        synchronizationTask?.cancel()
        // Window focus and owner cleanup can change SwiftUI state; wait until updateUIView returns.
        synchronizationTask = Task { @MainActor [weak self] in
            guard !Task.isCancelled else { return }
            self?.synchronizeWindow()
        }
    }

    private func synchronizeWindow() {
        let isLocked = session?.isLocked == true
        let needsCleanup = isLocked && !handledLock
        handledLock = isLocked
        if needsCleanup { onLock() }
        guard session?.isLocked == true, let sourceWindow, let scene = sourceWindow.windowScene,
              scene.activationState != .unattached else {
            removeLock()
            return
        }
        sourceWindow.endEditing(true)
        if let hostingController = lockWindow?.rootViewController as? UIHostingController<AnyView> {
            hostingController.rootView = content
            lockWindow?.frame = sourceWindow.frame
            if sourceWindow.isKeyWindow { lockWindow?.makeKey() }
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
            if let target, !target.isHidden, target.windowScene === scene { target.makeKey() }
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
