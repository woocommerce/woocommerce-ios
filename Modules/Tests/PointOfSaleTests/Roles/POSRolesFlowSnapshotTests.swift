import XCTest
import SwiftUI
import SnapshotTesting
import enum Experiments.FeatureFlag
@testable import PointOfSale

// MARK: - Snapshot Tests for POS Roles Views

final class POSRolesFlowSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    // MARK: - Flow 1: Local Settings

    func test_flow1_01_local_settings_pinOff_dark() {
        let pinService = POSPINService(storage: InMemoryPINStorage())
        UserDefaults.standard.set(false, forKey: "com.woocommerce.pos.pinAccessEnabled")
        let view = POSStaffSettingsView(mode: .local(pinService: pinService))
        snap(view, scheme: .dark)
    }

    func test_flow1_02_local_settings_pinOn_noPins_dark() {
        let pinService = POSPINService(storage: InMemoryPINStorage())
        UserDefaults.standard.set(true, forKey: "com.woocommerce.pos.pinAccessEnabled")
        let view = POSStaffSettingsView(mode: .local(pinService: pinService))
        snap(view, scheme: .dark)
    }

    func test_flow1_03_local_settings_ownerSet_dark() {
        let storage = InMemoryPINStorage()
        let pinService = POSPINService(storage: storage)
        pinService.setPIN("1234", for: .manager)
        UserDefaults.standard.set(true, forKey: "com.woocommerce.pos.pinAccessEnabled")
        let view = POSStaffSettingsView(mode: .local(pinService: pinService))
        snap(view, scheme: .dark)
    }

    func test_flow1_04_local_settings_bothSet_dark() {
        let storage = InMemoryPINStorage()
        let pinService = POSPINService(storage: storage)
        pinService.setPIN("1234", for: .manager)
        pinService.setPIN("5678", for: .cashier)
        UserDefaults.standard.set(true, forKey: "com.woocommerce.pos.pinAccessEnabled")
        let view = POSStaffSettingsView(mode: .local(pinService: pinService))
        snap(view, scheme: .dark)
    }

    func test_flow1_04_local_settings_bothSet_light() {
        let storage = InMemoryPINStorage()
        let pinService = POSPINService(storage: storage)
        pinService.setPIN("1234", for: .manager)
        pinService.setPIN("5678", for: .cashier)
        UserDefaults.standard.set(true, forKey: "com.woocommerce.pos.pinAccessEnabled")
        let view = POSStaffSettingsView(mode: .local(pinService: pinService))
        snap(view, scheme: .light)
    }

    // MARK: - Flow 2: Lock Screen

    func test_flow2_01_lockScreen_idle_dark() {
        let view = StatefulWrapper(initialState: POSPINEntryState.idle) { state in
            POSLockScreenView(
                pinState: state,
                onPINEntered: { _ in }
            )
        }
        snap(view, scheme: .dark)
    }

    func test_flow2_01_lockScreen_idle_light() {
        let view = StatefulWrapper(initialState: POSPINEntryState.idle) { state in
            POSLockScreenView(
                pinState: state,
                onPINEntered: { _ in }
            )
        }
        snap(view, scheme: .light)
    }

    func test_flow2_02_lockScreen_error_dark() {
        let view = StatefulWrapper(
            initialState: POSPINEntryState.error(message: "Invalid PIN")
        ) { state in
            POSLockScreenView(
                pinState: state,
                onPINEntered: { _ in }
            )
        }
        snap(view, scheme: .dark)
    }

    func test_flow2_03_lockScreen_lockout_dark() {
        let view = StatefulWrapper(
            initialState: POSPINEntryState.lockout(message: "Too many attempts. Try again in 30s.")
        ) { state in
            POSLockScreenView(
                pinState: state,
                onPINEntered: { _ in }
            )
        }
        snap(view, scheme: .dark)
    }

    // MARK: - Flow 3: Manager Override

    func test_flow3_01_override_refund_dark() {
        let view = StatefulWrapper(
            initialState: POSManagerOverrideState.awaitingPIN
        ) { state in
            POSManagerOverrideView(
                actionDescription: "Process a refund for Order #1042",
                capability: "woocommerce_refund_orders",
                overrideState: state,
                onPINEntered: { _ in },
                onCancelled: {}
            )
        }
        snap(view, scheme: .dark)
    }

    func test_flow3_01_override_refund_light() {
        let view = StatefulWrapper(
            initialState: POSManagerOverrideState.awaitingPIN
        ) { state in
            POSManagerOverrideView(
                actionDescription: "Process a refund for Order #1042",
                capability: "woocommerce_refund_orders",
                overrideState: state,
                onPINEntered: { _ in },
                onCancelled: {}
            )
        }
        snap(view, scheme: .light)
    }

    func test_flow3_02_override_error_dark() {
        let view = StatefulWrapper(
            initialState: POSManagerOverrideState.error(message: "Invalid PIN")
        ) { state in
            POSManagerOverrideView(
                actionDescription: "Process a refund for Order #1042",
                capability: "woocommerce_refund_orders",
                overrideState: state,
                onPINEntered: { _ in },
                onCancelled: {}
            )
        }
        snap(view, scheme: .dark)
    }

    func test_flow3_03_override_approved_dark() {
        let view = StatefulWrapper(
            initialState: POSManagerOverrideState.approved
        ) { state in
            POSManagerOverrideView(
                actionDescription: "Process a refund for Order #1042",
                capability: "woocommerce_refund_orders",
                overrideState: state,
                onPINEntered: { _ in },
                onCancelled: {}
            )
        }
        snap(view, scheme: .dark)
    }

    func test_flow3_04_override_coupon_dark() {
        let view = StatefulWrapper(
            initialState: POSManagerOverrideState.awaitingPIN
        ) { state in
            POSManagerOverrideView(
                actionDescription: "Create a new coupon for discount",
                capability: "woocommerce_apply_discounts",
                overrideState: state,
                onPINEntered: { _ in },
                onCancelled: {}
            )
        }
        snap(view, scheme: .dark)
    }

    func test_flow3_05_override_settings_dark() {
        let view = StatefulWrapper(
            initialState: POSManagerOverrideState.awaitingPIN
        ) { state in
            POSManagerOverrideView(
                actionDescription: "Open WordPress admin staff management",
                capability: "woocommerce_pos_manage_settings",
                overrideState: state,
                onPINEntered: { _ in },
                onCancelled: {}
            )
        }
        snap(view, scheme: .dark)
    }

    // MARK: - Flow 4: Remote Staff

    func test_flow4_01_remote_staff_allPins_dark() {
        let members = makeStaffMembers(allHavePINs: true)
        let view = POSStaffSettingsView(
            mode: .remote(
                staffMembers: members,
                manageURL: URL(string: "https://example.com/wp-admin")!
            )
        )
        snap(view, scheme: .dark)
    }

    func test_flow4_01_remote_staff_allPins_light() {
        let members = makeStaffMembers(allHavePINs: true)
        let view = POSStaffSettingsView(
            mode: .remote(
                staffMembers: members,
                manageURL: URL(string: "https://example.com/wp-admin")!
            )
        )
        snap(view, scheme: .light)
    }

    func test_flow4_02_remote_staff_mixedPins_dark() {
        let members: [StaffMemberInfo] = [
            StaffMemberInfo(id: 1, displayName: "Alice", role: "Administrator", hasPIN: true),
            StaffMemberInfo(id: 2, displayName: "Bob", role: "POS Manager", hasPIN: true),
            StaffMemberInfo(id: 3, displayName: "Carol", role: "POS Cashier", hasPIN: false),
            StaffMemberInfo(id: 4, displayName: "Dave", role: "Shop Manager", hasPIN: false)
        ]
        let view = POSStaffSettingsView(
            mode: .remote(
                staffMembers: members,
                manageURL: URL(string: "https://example.com/wp-admin")!
            )
        )
        snap(view, scheme: .dark)
    }

    func test_flow4_03_remote_staff_noPins_dark() {
        let members: [StaffMemberInfo] = [
            StaffMemberInfo(id: 1, displayName: "Alice", role: "Administrator", hasPIN: false),
            StaffMemberInfo(id: 2, displayName: "Bob", role: "POS Manager", hasPIN: false),
            StaffMemberInfo(id: 3, displayName: "Carol", role: "POS Cashier", hasPIN: false)
        ]
        let view = POSStaffSettingsView(
            mode: .remote(
                staffMembers: members,
                manageURL: URL(string: "https://example.com/wp-admin")!
            )
        )
        snap(view, scheme: .dark)
    }

    // MARK: - Flow 5: PIN Entry Component

    func test_flow5_01_pinEntry_idle_dark() {
        let view = StatefulWrapper(initialState: POSPINEntryState.idle) { state in
            POSPINEntryView(
                title: "Enter your PIN",
                subtitle: "Enter your 4-digit PIN to continue",
                state: state,
                onPINEntered: { _ in },
                onCancel: {}
            )
        }
        snap(view, scheme: .dark)
    }

    func test_flow5_01_pinEntry_idle_light() {
        let view = StatefulWrapper(initialState: POSPINEntryState.idle) { state in
            POSPINEntryView(
                title: "Enter your PIN",
                subtitle: "Enter your 4-digit PIN to continue",
                state: state,
                onPINEntered: { _ in },
                onCancel: {}
            )
        }
        snap(view, scheme: .light)
    }

    func test_flow5_02_pinEntry_error_dark() {
        let view = StatefulWrapper(
            initialState: POSPINEntryState.error(message: "Invalid PIN")
        ) { state in
            POSPINEntryView(
                title: "Enter your PIN",
                subtitle: "Enter your 4-digit PIN to continue",
                state: state,
                onPINEntered: { _ in },
                onCancel: {}
            )
        }
        snap(view, scheme: .dark)
    }

    func test_flow5_03_pinEntry_lockout_dark() {
        let view = StatefulWrapper(
            initialState: POSPINEntryState.lockout(
                message: "Too many attempts. Try again in 30s."
            )
        ) { state in
            POSPINEntryView(
                title: "Enter your PIN",
                subtitle: "Enter your 4-digit PIN to continue",
                state: state,
                onPINEntered: { _ in },
                onCancel: {}
            )
        }
        snap(view, scheme: .dark)
    }

    // MARK: - Settings (Staff Detail)

    func test_settings_staff_local_dark() {
        let storage = InMemoryPINStorage()
        let pinService = POSPINService(storage: storage)
        pinService.setPIN("1234", for: .manager)
        pinService.setPIN("5678", for: .cashier)
        UserDefaults.standard.set(true, forKey: "com.woocommerce.pos.pinAccessEnabled")

        let settingsView = POSSettingsView(
            settingsController: POSSettingsPreviewController(),
            staffSettingsMode: .local(pinService: pinService)
        )
        let featureFlags = AllEnabledPOSFeatureFlags()
        let view = settingsView
            .environment(\.posFeatureFlags, featureFlags)
        snap(view, scheme: .dark)
    }

    func test_settings_staff_remote_dark() {
        let members: [StaffMemberInfo] = [
            StaffMemberInfo(id: 1, displayName: "Alice", role: "Administrator", hasPIN: true),
            StaffMemberInfo(id: 2, displayName: "Bob", role: "POS Manager", hasPIN: true),
            StaffMemberInfo(id: 3, displayName: "Carol", role: "POS Cashier", hasPIN: false)
        ]
        let settingsView = POSSettingsView(
            settingsController: POSSettingsPreviewController(),
            staffSettingsMode: .remote(
                staffMembers: members,
                manageURL: URL(string: "https://example.com/wp-admin")!
            )
        )
        let featureFlags = AllEnabledPOSFeatureFlags()
        let view = settingsView
            .environment(\.posFeatureFlags, featureFlags)
        snap(view, scheme: .dark)
    }
}

// MARK: - Helpers

private extension POSRolesFlowSnapshotTests {

    func snap<V: View>(
        _ view: V,
        scheme: ColorScheme,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let host = view
            .environment(\.horizontalSizeClass, .regular)
            .environment(\.colorScheme, scheme)
            .frame(width: 1194, height: 834)

        let vc = UIHostingController(rootView: AnyView(host))
        vc.view.frame = CGRect(
            origin: .zero,
            size: CGSize(width: 1194, height: 834)
        )

        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(
                userInterfaceStyle: scheme == .dark ? .dark : .light
            ),
            UITraitCollection(horizontalSizeClass: .regular)
        ])

        assertSnapshot(
            of: vc,
            as: .image(
                on: ViewImageConfig(
                    safeArea: .zero,
                    size: CGSize(width: 1194, height: 834),
                    traits: traits
                )
            ),
            record: true,
            file: file,
            testName: testName,
            line: line
        )
    }

    func makeStaffMembers(allHavePINs: Bool) -> [StaffMemberInfo] {
        [
            StaffMemberInfo(
                id: 1, displayName: "Alice", role: "Administrator", hasPIN: allHavePINs
            ),
            StaffMemberInfo(
                id: 2, displayName: "Bob", role: "POS Manager", hasPIN: allHavePINs
            ),
            StaffMemberInfo(
                id: 3, displayName: "Carol", role: "POS Cashier", hasPIN: allHavePINs
            ),
            StaffMemberInfo(
                id: 4, displayName: "Dave", role: "Shop Manager", hasPIN: allHavePINs
            )
        ]
    }
}

// MARK: - StatefulWrapper

private struct StatefulWrapper<Content: View, S>: View {
    @State private var state: S
    let content: (Binding<S>) -> Content

    init(
        initialState: S,
        @ViewBuilder content: @escaping (Binding<S>) -> Content
    ) {
        _state = State(initialValue: initialState)
        self.content = content
    }

    var body: some View {
        content($state)
    }
}

// MARK: - Feature Flags

private struct AllEnabledPOSFeatureFlags: POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool { true }
}
