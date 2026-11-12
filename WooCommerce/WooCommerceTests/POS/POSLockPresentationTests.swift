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

    @Test func test_lock_when_native_sheet_is_open_then_discards_presentation() async throws {
        // Given
        let state = PresentationState()
        let window = try await mount(state)
        defer { unmount() }
        state.sheet = true
        try await waitUntil { window.rootViewController?.presentedViewController != nil }

        // When
        state.session.lock()
        try await waitUntil { !state.sheet }
        try await waitUntil { window.rootViewController?.presentedViewController == nil }

        // Then
        #expect(state.session.isLocked)
        #expect(!state.sheet)
        let gate = try #require(pinWindow(in: window))
        #expect(gate.windowScene === window.windowScene)
        #expect(gate.windowLevel > window.windowLevel)
        #expect(gate.isKeyWindow)
        #expect(window.accessibilityElementsHidden)
        #expect(gate.rootViewController?.view.accessibilityViewIsModal == true)
    }

    enum PresentationKind: CaseIterable, Sendable { case sheet, sheetItem, cover, coverItem }

    @Test(arguments: [PresentationKind.sheetItem, .cover, .coverItem])
    func test_lock_when_native_presentation_is_open_then_discards_binding(_ kind: PresentationKind) async throws {
        // Given
        let state = PresentationState()
        let window = try await mount(state)
        defer { unmount() }
        state.present(kind)
        try await waitUntil { window.rootViewController?.presentedViewController != nil }

        // When
        state.session.lock()
        try await waitUntil { !state.isPresented(kind) && window.rootViewController?.presentedViewController == nil }

        // Then
        #expect(pinWindow(in: window) != nil)
        state.session.isLocked = false
        try await waitUntil { self.pinWindow(in: window) == nil }
        #expect(!state.isPresented(kind))
    }

    @Test(arguments: PresentationKind.allCases)
    func test_late_presentation_when_locked_then_discards_request_without_restoring_on_unlock(_ kind: PresentationKind) async throws {
        // Given
        let state = PresentationState()
        state.session.isLocked = true
        let window = try await mount(state)
        defer { unmount() }
        try await waitUntil { self.pinWindow(in: window) != nil }

        // When
        state.present(kind)
        try await waitUntil { !state.isPresented(kind) }
        state.session.isLocked = false
        try await waitUntil { self.pinWindow(in: window) == nil }

        // Then
        #expect(window.rootViewController?.presentedViewController == nil)
        #expect(!window.accessibilityElementsHidden)
        state.present(kind)
        try await waitUntil { window.rootViewController?.presentedViewController != nil }
        try await waitUntil { window.rootViewController?.presentedViewController?.transitionCoordinator == nil }
        state.dismiss(kind)
        try await waitUntil { window.rootViewController?.presentedViewController == nil }
    }

    @Test func test_lock_when_keyboard_has_focus_then_restores_source_key_window_on_unlock() async throws {
        // Given
        let state = PresentationState()
        let window = try await mount(state)
        defer { unmount() }
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
        let state = PresentationState()
        let window = try await mount(state)
        defer { unmount() }
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

    @Test func test_source_movement_when_locked_then_restores_each_source_and_detaches_gate() async throws {
        // Given
        let state = PresentationState()
        let source = try await mount(state)
        let scene = try #require(source.windowScene)
        let nextSource = UIWindow(windowScene: scene)
        nextSource.rootViewController = UIViewController()
        let coordinator = POSLockPresentationHost<EmptyView>.Coordinator()
        defer { coordinator.detach(); nextSource.isHidden = true; unmount() }
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
        let state = PresentationState()
        state.session.isLocked = true
        let source = try await mount(state)
        defer { unmount() }
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
        let source = try await mount(PresentationState())
        let scene = try #require(source.windowScene)
        let prior = UIWindow(windowScene: scene)
        prior.rootViewController = UIViewController()
        prior.makeKeyAndVisible()
        let session = MockPOSAccessSession(isLocked: true)
        let coordinator = POSLockPresentationCoordinator()
        defer { coordinator.detach(); prior.isHidden = true; unmount() }
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

    @Test(arguments: [false, true])
    func test_custom_modal_when_locked_then_discards_ui_without_calling_payment_cancel(_ usesItem: Bool) async throws {
        // Given
        let state = PresentationState()
        let source = try await mount(state)
        defer { unmount() }
        state.presentCustomModal(usesItem: usesItem)
        try await waitUntil { state.modals.isPresented }

        // When
        state.session.lock()
        try await waitUntil { !state.customModalIsPresented(usesItem: usesItem) && !state.modals.isPresented }

        // Then
        #expect(state.dismissCalls == 0)
        state.session.isLocked = false
        try await waitUntil { self.pinWindow(in: source) == nil }
        #expect(!state.modals.isPresented)
        state.presentCustomModal(usesItem: usesItem)
        try await waitUntil { state.modals.isPresented }
        state.modals.dismiss()
        #expect(state.dismissCalls == 1)
    }

    @Test(arguments: [false, true])
    func test_late_custom_modal_when_locked_then_discards_request_without_restoring_on_unlock(_ usesItem: Bool) async throws {
        // Given
        let state = PresentationState()
        state.session.isLocked = true
        let source = try await mount(state)
        defer { unmount() }
        try await waitUntil { self.pinWindow(in: source) != nil }

        // When
        state.presentCustomModal(usesItem: usesItem)
        try await waitUntil { !state.customModalIsPresented(usesItem: usesItem) && !state.modals.isPresented }
        state.session.isLocked = false
        try await waitUntil { self.pinWindow(in: source) == nil }

        // Then
        #expect(!state.modals.isPresented)
        #expect(state.dismissCalls == 0)
    }

    @Test func test_replacing_and_removing_session_when_locked_then_keeps_one_current_gate_and_cleans_up() async throws {
        // Given
        let state = PresentationState()
        state.session.isLocked = true
        let oldSession = state.session
        let window = try await mount(state)
        defer { unmount() }
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

    @Test func test_lock_when_presenting_child_is_removed_then_owner_discards_modal_without_callback() async throws {
        // Given
        let state = PresentationState()
        let source = try await mount(state)
        defer { unmount() }
        state.modals.present(onDismiss: { state.dismissCalls += 1 }) { Text("Removed child") }
        state.presentingChild = false

        // When
        state.session.lock()
        try await waitUntil { self.pinWindow(in: source) != nil && !state.modals.isPresented }

        // Then
        #expect(state.dismissCalls == 0)
        #expect(state.lockCleanupCalls == 1)
        state.session.isLocked = false
        try await waitUntil { self.pinWindow(in: source) == nil }
        state.session.lock()
        try await waitUntil { state.lockCleanupCalls == 2 }
    }

    @Test func test_owner_cleanup_when_host_detaches_before_next_turn_then_discards_pending_callback() async {
        // Given
        let coordinator = POSLockPresentationCoordinator()
        let session = MockPOSAccessSession(isLocked: true)
        var calls = 0
        coordinator.update(session: session, content: AnyView(EmptyView()), onLock: { calls += 1 })
        #expect(calls == 0)

        // When
        coordinator.detach()
        await Task.yield()

        // Then
        #expect(calls == 0)
    }

    @Test func test_lock_when_swiftui_field_has_focus_then_allows_focus_again_after_unlock() async throws {
        // Given
        let state = PresentationState()
        state.showsSwiftUIField = true
        let source = try await mount(state)
        defer { unmount() }
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

    private func mount(_ state: PresentationState) async throws -> UIWindow {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive })
        try await waitUntil { !scene.windows.contains { $0.accessibilityIdentifier == "pos-lock-window" } }
        previousKeyWindow = scene.keyWindow
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView: PresentationFixture(state: state))
        self.window = window
        window.makeKeyAndVisible()
        try await waitUntil { self.findWindowAttachment(in: window.rootViewController?.view) }
        if state.session.isLocked { try await waitUntil { self.pinWindow(in: window) != nil } }
        return window
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
private final class PresentationState {
    var session = MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff)
    var mounted = true
    let field = UITextField()
    var sheet = false
    var sheetItem: Item?
    var cover = false
    var coverItem: Item?
    var modal = false
    var modalItem: Item?
    var presentingChild = true
    var lockCleanupCalls = 0
    var showsSwiftUIField = false
    var swiftUIFocusRequested = false
    var swiftUIHasFocus = false
    var swiftUIFocusRequestsHandled = 0
    var text = ""
    var dismissCalls = 0
    let modals = POSModalManager()

    struct Item: Identifiable, Equatable { let id = UUID() }

    func present(_ kind: POSLockPresentationTests.PresentationKind) {
        switch kind {
        case .sheet: sheet = true
        case .sheetItem: sheetItem = Item()
        case .cover: cover = true
        case .coverItem: coverItem = Item()
        }
    }

    func isPresented(_ kind: POSLockPresentationTests.PresentationKind) -> Bool {
        switch kind {
        case .sheet: sheet
        case .sheetItem: sheetItem != nil
        case .cover: cover
        case .coverItem: coverItem != nil
        }
    }

    func dismiss(_ kind: POSLockPresentationTests.PresentationKind) {
        switch kind {
        case .sheet: sheet = false
        case .sheetItem: sheetItem = nil
        case .cover: cover = false
        case .coverItem: coverItem = nil
        }
    }

    func presentCustomModal(usesItem: Bool) {
        if usesItem { modalItem = Item() } else { modal = true }
    }

    func customModalIsPresented(usesItem: Bool) -> Bool {
        usesItem ? modalItem != nil : modal
    }
}

private struct PresentationFixture: View {
    let state: PresentationState
    @StateObject private var sheets = POSSheetManager()
    @StateObject private var covers = POSFullScreenCoverManager()

    var body: some View {
        @Bindable var state = state
        Group {
            if state.mounted {
                Color.clear
                    .overlay { TextFieldFixture(field: state.field).frame(height: 40) }
                    .overlay {
                        if state.showsSwiftUIField { SwiftUIFocusFixture(state: state) }
                    }
                    .posSheet(isPresented: $state.sheet) { Text("Native sheet") }
                    .posSheet(item: $state.sheetItem) { _ in Text("Native item sheet") }
                    .posFullScreenCover(isPresented: $state.cover) { Text("Native cover") }
                    .posFullScreenCover(item: $state.coverItem) { _ in Text("Native item cover") }
                    .overlay {
                        if state.presentingChild {
                            Color.clear
                                .posModal(isPresented: $state.modal, onDismiss: { state.dismissCalls += 1 }) { Text("Custom modal") }
                                .posModal(item: $state.modalItem, onDismiss: { state.dismissCalls += 1 }) { _ in Text("Custom item modal") }
                        }
                    }
                    .posRootModal()
                    .posLockScreenOverlay {
                        state.lockCleanupCalls += 1
                        state.modals.dismissForLock()
                    }
            }
        }
            .environment(\.posAccessSession, state.session)
            .environmentObject(sheets)
            .environmentObject(covers)
            .environmentObject(state.modals)
    }
}

private struct SwiftUIFocusFixture: View {
    @Bindable var state: PresentationState
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

private struct TextFieldFixture: UIViewRepresentable {
    let field: UITextField
    func makeUIView(context: Context) -> UITextField { field }
    func updateUIView(_ uiView: UITextField, context: Context) {}
}
