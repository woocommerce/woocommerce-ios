import Observation
import SwiftUI
import Testing
import UIKit
@testable import PointOfSale

@MainActor
@Suite(.serialized, .timeLimit(.minutes(5)))
final class POSLockPresentationTests {
    private var window: UIWindow?
    private weak var previousKeyWindow: UIWindow?

    @Test(arguments: [false, true])
    func test_initial_entry_when_lock_state_is_known_then_only_locked_entry_installs_gate(_ locked: Bool) async throws {
        // Given
        let state = WindowPresentationState()
        state.session.isLocked = locked
        defer { unmount() }
        let source = try await mount(state)

        // Then
        #expect((pinWindow(in: source) != nil) == locked)
        #expect(source.accessibilityElementsHidden == locked)
        if let gate = pinWindow(in: source) {
            #expect(gate.windowScene === source.windowScene)
            #expect(gate.isKeyWindow)
            #expect(gate.rootViewController?.view.accessibilityViewIsModal == true)
            #expect(gate.rootViewController?.view.backgroundColor?.cgColor.alpha == 1)
        } else {
            #expect(source.isKeyWindow)
        }
    }

    enum NativePresentation: CaseIterable, Sendable { case sheet, cover }

    @Test(arguments: NativePresentation.allCases)
    func test_lock_when_native_presentation_exists_then_keeps_it_below_gate_and_restores_source_on_unlock(_ kind: NativePresentation) async throws {
        // Given
        let state = WindowPresentationState()
        defer { unmount() }
        let source = try await mount(state)
        state.present(kind)
        try await waitUntil { source.rootViewController?.presentedViewController != nil }
        let presented = try #require(source.rootViewController?.presentedViewController)

        // When
        state.session.lock()
        try await waitUntil { self.pinWindow(in: source)?.isKeyWindow == true }

        // Then - this foundation does not discard presentation state.
        let gate = try #require(pinWindow(in: source))
        #expect(gate.windowLevel > source.windowLevel)
        #expect(source.accessibilityElementsHidden)
        #expect(source.rootViewController?.presentedViewController === presented)
        #expect(state.isPresented(kind))
        state.session.isLocked = false
        try await waitUntil { self.pinWindow(in: source) == nil && source.isKeyWindow }
        #expect(source.rootViewController?.presentedViewController === presented)
        #expect(!source.accessibilityElementsHidden)
        state.dismiss(kind)
        try await waitUntil { source.rootViewController?.presentedViewController == nil }
    }

    @Test func test_late_native_controller_when_locked_then_cannot_take_pin_window_or_accessibility() async throws {
        // Given
        let state = WindowPresentationState()
        state.session.isLocked = true
        defer { unmount() }
        let source = try await mount(state)
        let gate = try #require(pinWindow(in: source))
        let root = try #require(source.rootViewController)
        let controller = UIViewController()
        controller.modalPresentationStyle = .fullScreen

        // When
        root.present(controller, animated: false)
        try await waitUntil { root.presentedViewController === controller && gate.isKeyWindow }

        // Then
        #expect(pinWindow(in: source) === gate)
        #expect(gate.windowLevel > source.windowLevel)
        #expect(source.accessibilityElementsHidden)
        #expect(gate.rootViewController?.view.accessibilityViewIsModal == true)
        try await waitUntil { root.presentedViewController?.transitionCoordinator == nil }
        controller.dismiss(animated: false)
        try await waitUntil { root.presentedViewController == nil }
    }

    @Test func test_lock_when_keyboard_has_focus_then_restores_source_key_window_on_unlock() async throws {
        // Given
        let state = WindowPresentationState()
        defer { unmount() }
        let window = try await mount(state)
        let field = state.field
        try #require(field.becomeFirstResponder())

        // When
        state.session.lock()
        try await waitUntil { self.pinWindow(in: window)?.isKeyWindow == true }

        // Then
        #expect(!field.isFirstResponder)
        state.session.isLocked = false
        try await waitUntil { self.pinWindow(in: window) == nil }
        #expect(window.isKeyWindow)
        #expect(field.becomeFirstResponder())
        window.endEditing(true)
    }

    @Test func test_lock_when_native_controller_is_presented_then_preserves_it_below_pin() async throws {
        // Given
        let state = WindowPresentationState()
        defer { unmount() }
        let window = try await mount(state)
        let nativeController = UIViewController()
        nativeController.modalPresentationStyle = .fullScreen
        await withCheckedContinuation { continuation in
            window.rootViewController?.present(nativeController, animated: false) { continuation.resume() }
        }
        try await waitUntil { window.rootViewController?.presentedViewController === nativeController }

        // When
        state.session.lock()
        try await waitUntil { self.pinWindow(in: window) != nil }

        // Then
        #expect(window.rootViewController?.presentedViewController === nativeController)
        #expect(window.accessibilityElementsHidden)
        state.session.isLocked = false
        try await waitUntil { self.pinWindow(in: window) == nil }
        #expect(window.rootViewController?.presentedViewController === nativeController)
        await withCheckedContinuation { continuation in
            nativeController.dismiss(animated: false) { continuation.resume() }
        }
    }

    @Test func test_source_requests_keyboard_while_locked_then_returns_focus_to_pin() async throws {
        // Given
        let state = WindowPresentationState()
        defer { unmount() }
        let source = try await mount(state)
        let presenter = try #require(source.rootViewController)
        let nativeController = UIViewController()
        let field = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        nativeController.view.addSubview(field)
        nativeController.modalPresentationStyle = .fullScreen
        await withCheckedContinuation { continuation in
            presenter.present(nativeController, animated: false) { continuation.resume() }
        }
        try #require(field.becomeFirstResponder())
        state.session.lock()
        try await waitUntil { self.pinWindow(in: source)?.isKeyWindow == true && !field.isFirstResponder }
        let gate = try #require(pinWindow(in: source))

        // When
        source.makeKey()
        try #require(field.becomeFirstResponder())

        // Then
        try await waitUntil { gate.isKeyWindow && !field.isFirstResponder }
        #expect(pinWindow(in: source) === gate)
        #expect(source.accessibilityElementsHidden)
        await withCheckedContinuation { continuation in
            presenter.dismiss(animated: false) { continuation.resume() }
        }
    }

    @Test func test_replaced_session_unlocks_while_current_session_is_locked_then_keeps_pin() async throws {
        // Given
        defer { unmount() }
        let source = try await mount(WindowPresentationState())
        let oldSession = MockPOSAccessSession(isLocked: true)
        let currentSession = MockPOSAccessSession(isLocked: true)
        let coordinator = POSLockPresentationCoordinator()
        defer { coordinator.detach() }
        coordinator.update(session: oldSession, content: AnyView(Color.clear))
        coordinator.attach(to: source)
        try await waitUntil { self.pinWindow(in: source)?.isKeyWindow == true }
        let gate = try #require(pinWindow(in: source))

        // When
        coordinator.update(session: currentSession, content: AnyView(Color.clear))
        oldSession.isLocked = false
        source.makeKey()

        // Then
        try await waitUntil { gate.isKeyWindow }
        #expect(pinWindow(in: source) === gate)
        #expect(currentSession.isLocked)
        #expect(source.accessibilityElementsHidden)
        currentSession.isLocked = false
        try await waitUntil { self.pinWindow(in: source) == nil && source.isKeyWindow }
        #expect(!source.accessibilityElementsHidden)
    }

    @Test func test_dismissing_pos_hosting_controller_while_locked_then_removes_pin_window() async throws {
        // Given
        defer { unmount() }
        let source = try await mount(WindowPresentationState())
        let presenter = try #require(source.rootViewController)
        let state = WindowPresentationState()
        let host = UIHostingController(rootView: WindowPresentationFixture(state: state))
        host.modalPresentationStyle = .fullScreen
        defer { state.mounted = false }
        await withCheckedContinuation { continuation in
            presenter.present(host, animated: false) { continuation.resume() }
        }
        state.session.lock()
        try await waitUntil { self.pinWindow(in: source)?.isKeyWindow == true }

        // When
        await withCheckedContinuation { continuation in
            presenter.dismiss(animated: false) { continuation.resume() }
        }

        // Then
        try await waitUntil { self.pinWindow(in: source) == nil && source.isKeyWindow }
        #expect(!source.accessibilityElementsHidden)
        #expect(host.presentingViewController == nil)
    }

    @Test func test_source_movement_when_locked_then_restores_each_source_and_detaches_gate() async throws {
        // Given
        let state = WindowPresentationState()
        defer { unmount() }
        let source = try await mount(state)
        let scene = try #require(source.windowScene)
        let nextSource = UIWindow(windowScene: scene)
        nextSource.rootViewController = UIViewController()
        let coordinator = POSLockPresentationHost<EmptyView>.Coordinator()
        defer { coordinator.detach(); nextSource.isHidden = true }
        coordinator.update(session: MockPOSAccessSession(isLocked: true), content: AnyView(Color.clear))
        coordinator.attach(to: source)
        try await waitUntil { self.pinWindow(in: source) != nil }
        let originalGate = try #require(pinWindow(in: source))

        // When
        nextSource.makeKeyAndVisible()
        coordinator.attach(to: nextSource)
        try await waitUntil { nextSource.accessibilityElementsHidden && self.pinWindow(in: nextSource) != nil }

        // Then
        #expect(!source.accessibilityElementsHidden)
        #expect(nextSource.accessibilityElementsHidden)
        #expect(pinWindow(in: nextSource) !== originalGate)
        #expect(originalGate.windowScene == nil)
        coordinator.detach()
        #expect(pinWindow(in: nextSource) == nil)
        #expect(!nextSource.accessibilityElementsHidden)
        #expect(nextSource.isKeyWindow)
    }

    @Test func test_scene_notifications_when_locked_then_retains_gate_and_recreates_after_disconnect() async throws {
        // Given
        let state = WindowPresentationState()
        state.session.isLocked = true
        defer { unmount() }
        let source = try await mount(state)
        let scene = try #require(source.windowScene)
        let gate = try #require(pinWindow(in: source))

        // When
        NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: scene)
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: scene)
        source.makeKey()
        try await waitUntil { gate.isKeyWindow }

        // Then
        #expect(pinWindow(in: source) === gate)
        #expect(gate.isKeyWindow)
        NotificationCenter.default.post(name: UIScene.didDisconnectNotification, object: scene)
        #expect(pinWindow(in: source) == nil)
        #expect(!source.accessibilityElementsHidden)
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: scene)
        try await waitUntil { self.pinWindow(in: source) != nil }
        #expect(pinWindow(in: source) != nil)
        #expect(scene.windows.filter { $0.accessibilityIdentifier == "pos-lock-window" }.count == 1)
    }

    @Test func test_unlock_when_prior_key_window_is_removed_then_restores_source() async throws {
        // Given
        defer { unmount() }
        let source = try await mount(WindowPresentationState())
        let scene = try #require(source.windowScene)
        let prior = UIWindow(windowScene: scene)
        prior.rootViewController = UIViewController()
        prior.makeKeyAndVisible()
        let session = MockPOSAccessSession(isLocked: true)
        let coordinator = POSLockPresentationCoordinator()
        defer { coordinator.detach(); prior.isHidden = true }
        coordinator.update(session: session, content: AnyView(Color.clear))
        coordinator.attach(to: source)
        try await waitUntil { self.pinWindow(in: source) != nil }

        // When
        prior.isHidden = true
        session.isLocked = false
        try await waitUntil { self.pinWindow(in: source) == nil }

        // Then
        #expect(source.isKeyWindow)
        #expect(!source.accessibilityElementsHidden)
    }

    @Test func test_replacing_and_removing_session_when_locked_then_keeps_one_current_gate_and_cleans_up() async throws {
        // Given
        let state = WindowPresentationState()
        state.session.isLocked = true
        let oldSession = state.session
        defer { unmount() }
        let window = try await mount(state)
        try await waitUntil { self.pinWindow(in: window) != nil }

        // When
        state.session = MockPOSAccessSession(isLocked: true)
        oldSession.isLocked = false
        state.mounted = false
        try await waitUntil { self.pinWindow(in: window) == nil }

        // Then
        #expect(window.isKeyWindow)
        #expect(!window.accessibilityElementsHidden)
        state.mounted = true
        try await waitUntil { self.pinWindow(in: window) != nil }
        #expect(window.windowScene?.windows.filter { $0.accessibilityIdentifier == "pos-lock-window" }.count == 1)
        #expect(state.session.isLocked)
        state.session.isLocked = false
        try await waitUntil { self.pinWindow(in: window) == nil }
        #expect(window.isKeyWindow)
    }

    @Test func test_lock_when_swiftui_field_has_focus_then_allows_focus_again_after_unlock() async throws {
        // Given
        let state = WindowPresentationState()
        state.showsSwiftUIField = true
        defer { unmount() }
        let source = try await mount(state)
        state.swiftUIFocusRequested = true
        try await waitUntil { state.swiftUIHasFocus }

        // When
        state.session.lock()
        try await waitUntil { self.pinWindow(in: source)?.isKeyWindow == true && !state.swiftUIHasFocus }
        state.session.isLocked = false
        try await waitUntil { self.pinWindow(in: source) == nil && source.isKeyWindow }
        let handledRequests = state.swiftUIFocusRequestsHandled
        state.swiftUIFocusRequested = false
        try await waitUntil { state.swiftUIFocusRequestsHandled > handledRequests }
        state.swiftUIFocusRequested = true

        // Then
        try await waitUntil { state.swiftUIHasFocus }
        #expect(!source.accessibilityElementsHidden)
    }

    private func pinWindow(in source: UIWindow) -> UIWindow? {
        source.windowScene?.windows.first { $0.accessibilityIdentifier == "pos-lock-window" && !$0.isHidden }
    }

    private func mount(_ state: WindowPresentationState) async throws -> UIWindow {
        let source = try await mountView(WindowPresentationFixture(state: state))
        if state.session.isLocked { try await waitUntil { self.pinWindow(in: source) != nil } }
        return source
    }

    private func mountView<Content: View>(_ content: Content) async throws -> UIWindow {
        try await waitUntil {
            UIApplication.shared.connectedScenes.contains { $0 is UIWindowScene && $0.activationState != .unattached }
        }
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState != .unattached })
        try await waitUntil { !scene.windows.contains { $0.accessibilityIdentifier == "pos-lock-window" } }
        previousKeyWindow = scene.keyWindow
        let source = UIWindow(windowScene: scene)
        source.rootViewController = UIHostingController(rootView: content)
        window = source
        source.makeKeyAndVisible()
        try await waitUntil { self.findWindowAttachment(in: source.rootViewController?.view) }
        return source
    }

    private func findWindowAttachment(in view: UIView?) -> Bool {
        guard let view else { return false }
        if view is WindowFinderView, view.window === window { return true }
        return view.subviews.contains { findWindowAttachment(in: $0) }
    }

    private func unmount() {
        window?.rootViewController = nil
        window?.isHidden = true
        window = nil
        previousKeyWindow?.makeKey()
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<200 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(condition())
    }
}

@MainActor
@Observable
private final class WindowPresentationState {
    var session = MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff)
    var mounted = true
    let field = UITextField()
    var sheet = false
    var cover = false
    var showsSwiftUIField = false
    var swiftUIFocusRequested = false
    var swiftUIHasFocus = false
    var swiftUIFocusRequestsHandled = 0
    var text = ""

    func present(_ kind: POSLockPresentationTests.NativePresentation) {
        if kind == .sheet { sheet = true } else { cover = true }
    }

    func isPresented(_ kind: POSLockPresentationTests.NativePresentation) -> Bool {
        kind == .sheet ? sheet : cover
    }

    func dismiss(_ kind: POSLockPresentationTests.NativePresentation) {
        if kind == .sheet { sheet = false } else { cover = false }
    }
}

private struct WindowPresentationFixture: View {
    let state: WindowPresentationState

    var body: some View {
        @Bindable var state = state
        Group {
            if state.mounted {
                Color.clear
                    .overlay { WindowTextFieldFixture(field: state.field).frame(height: 40) }
                    .overlay {
                        if state.showsSwiftUIField { WindowFocusFixture(state: state) }
                    }
                    .sheet(isPresented: $state.sheet) { Text("Native sheet") }
                    .fullScreenCover(isPresented: $state.cover) { Text("Native cover") }
                    .posLockScreenOverlay()
            }
        }
        .environment(\.posAccessSession, state.session)
    }
}

private struct WindowFocusFixture: View {
    @Bindable var state: WindowPresentationState
    @FocusState private var focused: Bool

    var body: some View {
        TextField("Editor", text: $state.text)
            .focused($focused)
            .onChange(of: state.swiftUIFocusRequested) {
                focused = state.swiftUIFocusRequested
                state.swiftUIFocusRequestsHandled += 1
            }
            .onChange(of: focused) { state.swiftUIHasFocus = focused }
    }
}

private struct WindowTextFieldFixture: UIViewRepresentable {
    let field: UITextField
    func makeUIView(context: Context) -> UITextField { field }
    func updateUIView(_ uiView: UITextField, context: Context) {}
}
