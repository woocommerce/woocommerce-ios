import Combine
import SwiftUI

@MainActor
final class LocalOperatorHostingController: UIHostingController<LocalOperatorLockView> {
    init(sessionController: LocalOperatorSessionControlling? = nil) {
        let resolvedSessionController = sessionController ?? ServiceLocator.localOperatorSessionController
        super.init(rootView: LocalOperatorLockView(sessionController: resolvedSessionController))
        modalPresentationStyle = .fullScreen
        isModalInPresentation = true
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
struct LocalOperatorLockView: View {
    @ObservedObject private var sessionController: LocalOperatorSessionControllerAdapter

    init(sessionController: LocalOperatorSessionControlling) {
        self.sessionController = LocalOperatorSessionControllerAdapter(base: sessionController)
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessionController.requiresBootstrap {
                    LocalOperatorBootstrapView(sessionController: sessionController)
                } else {
                    LocalOperatorUnlockView(sessionController: sessionController)
                }
            }
            .navigationTitle(Localization.lockTitle)
        }
    }
}

@MainActor
struct LocalOperatorManagementView: View {
    @ObservedObject private var sessionController: LocalOperatorSessionControllerAdapter
    @State private var selectedTimeout: TimeInterval = 5 * 60
    @State private var draftOperator = LocalOperatorDraft()
    @State private var editingOperator: LocalOperatorProfile?

    init(sessionController: LocalOperatorSessionControlling) {
        self.sessionController = LocalOperatorSessionControllerAdapter(base: sessionController)
        _selectedTimeout = State(initialValue: sessionController.inactivityTimeout)
    }

    var body: some View {
        Form {
            Section(Localization.modeSectionTitle) {
                Toggle(Localization.enableModeToggle, isOn: Binding(
                    get: { sessionController.isDeviceStaffModeEnabled },
                    set: { isEnabled in
                        if isEnabled {
                            sessionController.enableDeviceStaffMode()
                        } else {
                            sessionController.disableDeviceStaffMode()
                        }
                    }
                ))

                Picker(Localization.timeoutLabel, selection: $selectedTimeout) {
                    Text(Localization.timeoutOneMinute).tag(60.0)
                    Text(Localization.timeoutFiveMinutes).tag(5 * 60.0)
                    Text(Localization.timeoutFifteenMinutes).tag(15 * 60.0)
                }
                .onChange(of: selectedTimeout) { _, newValue in
                    sessionController.inactivityTimeout = newValue
                }
                .disabled(sessionController.isDeviceStaffModeEnabled == false)
            }

            if sessionController.isDeviceStaffModeEnabled {
                Section(Localization.sessionSectionTitle) {
                    LabeledContent(Localization.currentOperatorLabel) {
                        Text(sessionController.activeOperator?.displayName ?? Localization.lockedValue)
                            .foregroundStyle(.secondary)
                    }

                    Button(Localization.switchOperatorButton) {
                        sessionController.lock()
                    }
                }

                Section(Localization.operatorsSectionTitle) {
                    ForEach(sessionController.profiles) { profile in
                        Button {
                            editingOperator = profile
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profile.displayName)
                                    Text(profile.role.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if profile.isEnabled == false {
                                    Text(Localization.disabledLabel)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Button(Localization.addOperatorButton) {
                        draftOperator = LocalOperatorDraft()
                        draftOperator.isPresenting = true
                    }
                }
            }
        }
        .navigationTitle(Localization.managementTitle)
        .sheet(item: $editingOperator) { profile in
            let lastManagerProtected = sessionController.isLastManagerProtected(profile)
            LocalOperatorEditorView(
                title: Localization.editOperatorTitle,
                draft: LocalOperatorDraft(profile: profile),
                canDelete: sessionController.canDeleteOperator(profile),
                showsDeleteResetWarning: sessionController.profiles.count == 1,
                showsManagerProtectionWarning: lastManagerProtected,
                canSave: { draft in
                    sessionController.canSaveOperator(profile: profile, draft: draft)
                }
            ) { result in
                switch result {
                case .save(let draft):
                    var updated = profile
                    updated.displayName = draft.displayName
                    updated.role = draft.role
                    updated.isEnabled = draft.isEnabled
                    try? sessionController.updateOperator(updated, newPIN: draft.pin.isEmpty ? nil : draft.pin)
                case .delete:
                    sessionController.deleteOperator(profile)
                case .cancel:
                    break
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { draftOperator.isPresenting },
            set: { draftOperator.isPresenting = $0 }
        )) {
            LocalOperatorEditorView(
                title: Localization.addOperatorTitle,
                draft: draftOperator,
                canDelete: false,
                showsDeleteResetWarning: false,
                showsManagerProtectionWarning: false,
                canSave: { draft in
                    draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                }
            ) { result in
                defer { draftOperator.isPresenting = false }
                guard case let .save(draft) = result else {
                    return
                }
                try? sessionController.addOperator(displayName: draft.displayName, role: draft.role, pin: draft.pin)
            }
        }
    }
}

@MainActor
private struct LocalOperatorUnlockView: View {
    @ObservedObject var sessionController: LocalOperatorSessionControllerAdapter
    @State private var selectedOperatorID: UUID?
    @State private var pin = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(Localization.pickOperatorTitle) {
                Picker(Localization.operatorLabel, selection: $selectedOperatorID) {
                    Text(Localization.selectOperatorPlaceholder).tag(UUID?.none)
                    ForEach(sessionController.profiles.filter(\.isEnabled)) { profile in
                        Text(profile.displayName).tag(UUID?.some(profile.id))
                    }
                }
            }

            Section(Localization.pinSectionTitle) {
                SecureField(Localization.pinPlaceholder, text: $pin)
                    .keyboardType(.numberPad)
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button(Localization.unlockButton) {
                    guard let selectedOperatorID else {
                        errorMessage = Localization.selectOperatorError
                        return
                    }
                    if sessionController.unlock(operatorID: selectedOperatorID, pin: pin) {
                        pin = ""
                        errorMessage = nil
                    } else {
                        errorMessage = Localization.invalidPinError
                    }
                }
            }
        }
    }
}

@MainActor
private struct LocalOperatorBootstrapView: View {
    @ObservedObject var sessionController: LocalOperatorSessionControllerAdapter
    @State private var name = ""
    @State private var pin = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(Localization.bootstrapDescriptionTitle) {
                Text(Localization.bootstrapDescription)
                    .font(.subheadline)
            }

            Section(Localization.bootstrapManagerTitle) {
                TextField(Localization.operatorNamePlaceholder, text: $name)
                SecureField(Localization.pinPlaceholder, text: $pin)
                    .keyboardType(.numberPad)
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button(Localization.createManagerButton) {
                    do {
                        try sessionController.bootstrapManager(displayName: name, pin: pin)
                        errorMessage = nil
                    } catch {
                        errorMessage = Localization.invalidPinError
                    }
                }
            }
        }
    }
}

@MainActor
private struct LocalOperatorEditorView: View {
    enum Result {
        case save(LocalOperatorDraft)
        case delete
        case cancel
    }

    let title: String
    @State var draft: LocalOperatorDraft
    let canDelete: Bool
    let showsDeleteResetWarning: Bool
    let showsManagerProtectionWarning: Bool
    let canSave: (LocalOperatorDraft) -> Bool
    let onComplete: (Result) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(Localization.detailsSectionTitle) {
                    TextField(Localization.operatorNamePlaceholder, text: $draft.displayName)
                    Picker(Localization.roleLabel, selection: $draft.role) {
                        ForEach(LocalOperatorRole.allCases) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    Toggle(Localization.enabledToggle, isOn: $draft.isEnabled)
                }

                Section(Localization.pinSectionTitle) {
                    SecureField(Localization.pinPlaceholder, text: $draft.pin)
                        .keyboardType(.numberPad)
                    Text(Localization.pinHelpText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if canDelete {
                    Section {
                        Button(Localization.deleteButton, role: .destructive) {
                            dismiss()
                            onComplete(.delete)
                        }

                        if showsDeleteResetWarning {
                            Text(Localization.deleteResetWarning)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if showsManagerProtectionWarning {
                    Section {
                        Text(Localization.managerProtectionWarning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        dismiss()
                        onComplete(.cancel)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.saveButton) {
                        dismiss()
                        onComplete(.save(draft))
                    }
                    .disabled(canSave(draft) == false)
                }
            }
        }
    }
}

@MainActor
private final class LocalOperatorSessionControllerAdapter: ObservableObject {
    let base: LocalOperatorSessionControlling
    private var subscriptions = Set<AnyCancellable>()

    init(base: LocalOperatorSessionControlling) {
        self.base = base
        if let base = base as? LocalOperatorSessionController {
            base.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &subscriptions)
        }
    }

    var profiles: [LocalOperatorProfile] { base.profiles }
    var activeOperator: LocalOperatorProfile? { base.activeOperator }
    var isLocked: Bool { base.isLocked }
    var requiresBootstrap: Bool { base.requiresBootstrap }
    var isDeviceStaffModeEnabled: Bool { base.isDeviceStaffModeEnabled }

    var inactivityTimeout: TimeInterval {
        get { base.inactivityTimeout }
        set { base.inactivityTimeout = newValue }
    }

    private var enabledManagers: [LocalOperatorProfile] {
        profiles.filter { $0.role == .manager && $0.isEnabled }
    }

    func isLastManagerProtected(_ profile: LocalOperatorProfile) -> Bool {
        profile.role == .manager && profile.isEnabled && enabledManagers.count == 1 && profiles.count > 1
    }

    func canDeleteOperator(_ profile: LocalOperatorProfile) -> Bool {
        isLastManagerProtected(profile) == false || profiles.count == 1
    }

    func canSaveOperator(profile: LocalOperatorProfile, draft: LocalOperatorDraft) -> Bool {
        guard draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return false
        }

        let isRemovingManagerAccess = profile.role == .manager
            && profile.isEnabled
            && (draft.role != .manager || draft.isEnabled == false)

        if isRemovingManagerAccess && enabledManagers.count == 1 && profiles.count > 1 {
            return false
        }

        return true
    }

    func enableDeviceStaffMode() {
        base.enableDeviceStaffMode()
    }

    func disableDeviceStaffMode() {
        base.disableDeviceStaffMode()
    }

    func lock() {
        base.lock()
    }

    func bootstrapManager(displayName: String, pin: String) throws {
        try base.bootstrapManager(displayName: displayName, pin: pin)
    }

    func unlock(operatorID: UUID, pin: String) -> Bool {
        base.unlock(operatorID: operatorID, pin: pin)
    }

    func addOperator(displayName: String, role: LocalOperatorRole, pin: String) throws {
        try base.addOperator(displayName: displayName, role: role, pin: pin)
    }

    func updateOperator(_ profile: LocalOperatorProfile, newPIN: String?) throws {
        try base.updateOperator(profile, newPIN: newPIN)
    }

    func deleteOperator(_ profile: LocalOperatorProfile) {
        base.deleteOperator(profile)
    }
}

private struct LocalOperatorDraft: Identifiable {
    let id = UUID()
    var displayName = ""
    var role: LocalOperatorRole = .cashier
    var isEnabled = true
    var pin = ""
    var isPresenting = false

    init() {}

    init(profile: LocalOperatorProfile) {
        self.displayName = profile.displayName
        self.role = profile.role
        self.isEnabled = profile.isEnabled
        self.isPresenting = false
    }
}

private extension LocalOperatorLockView {
    enum Localization {
        static let lockTitle = NSLocalizedString("Device Staff Mode", comment: "Title for the local operator lock screen.")
    }
}

private extension LocalOperatorManagementView {
    enum Localization {
        static let managementTitle = NSLocalizedString("Device Staff Mode", comment: "Title for the local operator management screen.")
        static let modeSectionTitle = NSLocalizedString("Access", comment: "Title for the local operator access settings section.")
        static let sessionSectionTitle = NSLocalizedString("Session", comment: "Title for the current operator session section.")
        static let currentOperatorLabel = NSLocalizedString("Current Operator", comment: "Label showing the currently unlocked operator.")
        static let lockedValue = NSLocalizedString("Locked", comment: "Value shown when no operator is currently active.")
        static let switchOperatorButton = NSLocalizedString("Switch Operator", comment: "Button title for locking and switching the current operator.")
        static let enableModeToggle = NSLocalizedString("Enable Device Staff Mode", comment: "Toggle to enable local operator mode.")
        static let timeoutLabel = NSLocalizedString("Auto-Lock Timeout", comment: "Label for the device staff mode timeout picker.")
        static let timeoutOneMinute = NSLocalizedString("1 minute", comment: "One minute timeout option for local operator mode.")
        static let timeoutFiveMinutes = NSLocalizedString("5 minutes", comment: "Five minute timeout option for local operator mode.")
        static let timeoutFifteenMinutes = NSLocalizedString("15 minutes", comment: "Fifteen minute timeout option for local operator mode.")
        static let operatorsSectionTitle = NSLocalizedString("Operators", comment: "Title for the local operator list.")
        static let disabledLabel = NSLocalizedString("Disabled", comment: "Label for a disabled local operator.")
        static let addOperatorButton = NSLocalizedString("Add Operator", comment: "Button title to add a new local operator.")
        static let editOperatorTitle = NSLocalizedString("Edit Operator", comment: "Title for editing a local operator.")
        static let addOperatorTitle = NSLocalizedString("Add Operator", comment: "Title for creating a new local operator.")
    }
}

private extension LocalOperatorUnlockView {
    enum Localization {
        static let pickOperatorTitle = NSLocalizedString("Operator", comment: "Title for the local operator picker section.")
        static let operatorLabel = NSLocalizedString("Next Operator", comment: "Label for selecting which local operator should unlock the device next.")
        static let selectOperatorPlaceholder = NSLocalizedString("Select operator", comment: "Placeholder for selecting a local operator.")
        static let pinSectionTitle = NSLocalizedString("PIN", comment: "Title for the local operator pin section.")
        static let pinPlaceholder = NSLocalizedString("Enter PIN", comment: "Placeholder for entering the local operator pin.")
        static let unlockButton = NSLocalizedString("Unlock", comment: "Button title for unlocking local operator mode.")
        static let invalidPinError = NSLocalizedString("Invalid PIN. Try again.", comment: "Error shown when a local operator pin is invalid.")
        static let selectOperatorError = NSLocalizedString("Choose an operator to continue.", comment: "Error shown when no local operator is selected.")
    }
}

private extension LocalOperatorBootstrapView {
    enum Localization {
        static let bootstrapDescriptionTitle = NSLocalizedString("Set Up Access", comment: "Title for the bootstrap description section.")
        static let bootstrapDescription = NSLocalizedString(
            "Create the first manager profile for this shared device. This PIN unlocks restricted areas without changing the Woo account signed into the app.",
            comment: "Description for bootstrapping the first local operator."
        )
        static let bootstrapManagerTitle = NSLocalizedString("First Manager", comment: "Title for bootstrapping the first manager.")
        static let operatorNamePlaceholder = NSLocalizedString("Display name", comment: "Placeholder for the local operator display name.")
        static let pinPlaceholder = NSLocalizedString("Choose a 4-6 digit PIN", comment: "Placeholder for the local operator pin.")
        static let createManagerButton = NSLocalizedString("Create Manager", comment: "Button title for creating the first local operator manager.")
        static let invalidPinError = NSLocalizedString("Enter a 4-6 digit PIN.", comment: "Error shown when the local operator pin is invalid.")
    }
}

private extension LocalOperatorEditorView {
    enum Localization {
        static let detailsSectionTitle = NSLocalizedString("Details", comment: "Title for local operator details section.")
        static let operatorNamePlaceholder = NSLocalizedString("Display name", comment: "Placeholder for local operator name.")
        static let roleLabel = NSLocalizedString("Role", comment: "Label for local operator role picker.")
        static let enabledToggle = NSLocalizedString("Enabled", comment: "Toggle label for enabling a local operator.")
        static let pinSectionTitle = NSLocalizedString("PIN", comment: "Title for the local operator pin section.")
        static let pinPlaceholder = NSLocalizedString("Set new PIN", comment: "Placeholder for setting a new local operator pin.")
        static let pinHelpText = NSLocalizedString("Leave blank to keep the current PIN.", comment: "Help text for local operator PIN editing.")
        static let deleteButton = NSLocalizedString("Delete Operator", comment: "Button title for deleting a local operator.")
        static let deleteResetWarning = NSLocalizedString(
            "Deleting the last operator will require setting up a new manager before this device can be unlocked again.",
            comment: "Warning shown when deleting the final local operator."
        )
        static let managerProtectionWarning = NSLocalizedString(
            "This device must keep at least one enabled manager unless you are deleting all operators and resetting setup.",
            comment: "Warning shown when the last manager cannot be demoted, disabled, or deleted while other operators still exist."
        )
        static let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title for local operator editing.")
        static let saveButton = NSLocalizedString("Save", comment: "Save button title for local operator editing.")
    }
}
