import SwiftUI
import UIKit
import Observation

struct POSLockPresentationHost<LockContent: View>: UIViewControllerRepresentable {
    let session: POSAccessSession
    let locksInBackground: () -> Bool
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
        context.coordinator.update(session: session, content: AnyView(content), locksInBackground: locksInBackground)
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
    private let privacyCover = POSPrivacyCoverView(frame: .zero)
    private var sourceAccessibilityHidden = false
    private var sourceInteractionEnabled = true
    private var sceneIsInactive = false
    private var locksInBackground: () -> Bool = { false }
    private var session: POSAccessSession?
    private var observationID = UUID()
    private var content = AnyView(EmptyView())
    private var synchronizationTask: Task<Void, Never>?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(sceneDeactivating), name: UIScene.willDeactivateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneBackgrounded), name: UIScene.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneActivated), name: UIScene.didActivateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneDisconnected), name: UIScene.didDisconnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sourceBecameKey), name: UIWindow.didBecomeKeyNotification, object: nil)
    }

    func attach(to window: UIWindow) {
        if sourceWindow !== window {
            removeLock()
            privacyCover.removeFromSuperview()
            sourceWindow = window
            sceneIsInactive = window.windowScene?.activationState != .foregroundActive
        }
        synchronize()
    }

    func update(session: POSAccessSession, content: AnyView, locksInBackground: @escaping () -> Bool = { false }) {
        let sessionChanged = self.session !== session
        self.session = session
        self.content = content
        self.locksInBackground = locksInBackground
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
        privacyCover.removeFromSuperview()
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
        updateSourcePrivacy(forInactiveScene: sceneIsInactive)
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
        sourceInteractionEnabled = sourceWindow.isUserInteractionEnabled
        sourceWindow.isUserInteractionEnabled = false
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
        sourceWindow?.isUserInteractionEnabled = sourceInteractionEnabled
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

    private var shouldLockInBackground: Bool {
        session?.isPINProtectionEnabled == true && session?.isLocked == false &&
            session?.currentStaff != nil && locksInBackground()
    }

    private func updateSourcePrivacy(forInactiveScene isInactive: Bool) {
        guard let sourceWindow, session?.isLocked == true || (isInactive && shouldLockInBackground) else {
            privacyCover.removeFromSuperview()
            return
        }
        privacyCover.frame = sourceWindow.bounds
        sourceWindow.addSubview(privacyCover)
    }

    @objc private func sceneDeactivating(_ notification: Notification) {
        guard notification.object as? UIWindowScene === sourceWindow?.windowScene else { return }
        sceneIsInactive = true
        // Cover native POS presentations before the system takes its app-switcher snapshot.
        updateSourcePrivacy(forInactiveScene: true)
    }

    @objc private func sceneBackgrounded(_ notification: Notification) {
        guard notification.object as? UIWindowScene === sourceWindow?.windowScene else { return }
        if shouldLockInBackground { session?.lock() }
        synchronizeWindow()
    }

    @objc private func sceneActivated(_ notification: Notification) {
        guard notification.object as? UIWindowScene === sourceWindow?.windowScene else { return }
        sceneIsInactive = false
        synchronizeWindow()
    }

    @objc private func sceneDisconnected(_ notification: Notification) {
        guard notification.object as? UIWindowScene === sourceWindow?.windowScene else { return }
        synchronizationTask?.cancel()
        removeLock()
        privacyCover.removeFromSuperview()
    }
}

private final class POSPrivacyCoverView: UIView {
    private let catalogPanel = UIView()
    private let cartPanel = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))

    override init(frame: CGRect) {
        super.init(frame: frame)
        // The material samples these generic panels over an opaque base, so the scene snapshot cannot contain sale data.
        backgroundColor = UIColor(Color.posSurfaceContainerLow)
        isOpaque = true
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        catalogPanel.backgroundColor = UIColor(Color.posSurfaceContainerHighest)
        cartPanel.backgroundColor = UIColor(Color.posPrimary).withAlphaComponent(0.55)
        addSubview(catalogPanel)
        addSubview(cartPanel)
        addSubview(blurView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        let height = bounds.height
        let cornerRadius = min(width, height) * 0.08
        catalogPanel.frame = CGRect(x: width * 0.08, y: height * 0.15, width: width * 0.64, height: height * 0.45)
        catalogPanel.layer.cornerRadius = cornerRadius
        cartPanel.frame = CGRect(x: width * 0.42, y: height * 0.42, width: width * 0.50, height: height * 0.43)
        cartPanel.layer.cornerRadius = cornerRadius
        blurView.frame = bounds
    }
}
