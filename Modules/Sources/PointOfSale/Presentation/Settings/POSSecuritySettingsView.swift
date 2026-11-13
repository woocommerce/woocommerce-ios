import SwiftUI

struct POSSecuritySettingsView: View {
    @Environment(\.posMetrics) private var metrics
    let controller: POSSecuritySettingsController
    @State private var editing: POSLocalRole?
    @State private var removalApproval = POSManagerOverrideHandler()
    @State private var removalApprovalTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            POSPageHeaderView(title: Localization.title)
            ScrollView {
                VStack(alignment: .leading, spacing: metrics.spacing.medium) {
                    if let roles = controller.roles {
                        if controller.isPINProtectionEnabled {
                            POSInformationCard {
                                POSInformationCardFieldRowWithToggle(label: Localization.pinProtection,
                                                                     value: Localization.protectionOn,
                                                                     showSeparator: false,
                                                                     isOn: protectionBinding)
                            }
                        } else {
                            Text(Localization.protectionOff).font(.posBodyMediumRegular())
                        }
                        POSInformationCard {
                            ViewThatFits(in: .horizontal) {
                                pinRows(roles, stacked: false)
                                pinRows(roles, stacked: true)
                            }
                        }
                        if controller.hasOnlyAdminPIN { Text(Localization.adminOnlyExplanation).font(.posBodyMediumRegular()) }
                    } else {
                        Button(Localization.retry) { controller.load() }
                            .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: .default))
                    }
                    if let error = controller.error {
                        Text(error == .pinMatchesOtherRole ? Localization.distinctPINs : Localization.storageError)
                            .foregroundStyle(Color.posError).font(.posBodyMediumRegular())
                    }
                }
                .posContentPadding(.horizontal, metrics.padding.medium)
                .posPadding(.vertical, \.medium)
            }
        }
        .background(Color.posSurface)
        .disabled(controller.isSaving)
        .onAppear { controller.load() }
        .onDisappear { editing = nil; dismissRemovalApproval() }
        .onChange(of: controller.isVisible) { _, isVisible in
            if !isVisible { dismissRemovalApproval() }
        }
        .posModal(isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } }),
                  onDismiss: { controller.load() }) {
            if let role = editing {
                POSSecurityPINEntryModal(role: role, controller: controller, close: { editing = nil })
            }
        }
        .posManagerOverrideModal(handler: removalApproval)
        .accessibilityIdentifier("pos-security-settings")
    }

    private var protectionBinding: Binding<Bool> {
        Binding(get: { controller.isPINProtectionEnabled }, set: { isEnabled in
            if !isEnabled {
                removalApprovalTask?.cancel()
                removalApprovalTask = Task {
                    _ = await controller.requestProtectionRemoval(using: removalApproval, reason: Localization.disableProtectionReason)
                }
            }
        })
    }

    private func dismissRemovalApproval() {
        removalApprovalTask?.cancel()
        removalApprovalTask = nil
        removalApproval.cancel()
    }

    private func pinRows(_ roles: Set<POSLocalRole>, stacked: Bool) -> some View {
        VStack(spacing: metrics.spacing.medium) {
            pinRow(.admin, roles: roles, stacked: stacked)
            if controller.offersCashierPINSetup {
                Divider().padding(.top, metrics.padding.small)
                pinRow(.cashier, roles: roles, stacked: stacked)
            }
        }
    }

    @ViewBuilder
    private func pinRow(_ role: POSLocalRole, roles: Set<POSLocalRole>, stacked: Bool) -> some View {
        let details = POSInformationCardFieldRow(label: String.localizedStringWithFormat(Localization.rolePIN, role.displayName),
                                                 value: roles.contains(role) ? Localization.pinSet : Localization.noPIN,
                                                 showSeparator: false)
        let actions = HStack(spacing: metrics.spacing.medium) {
            Button(roles.contains(role) ? Localization.change : Localization.setPIN) {
                controller.load(); editing = role
            }
            .accessibilityLabel(String.localizedStringWithFormat(
                roles.contains(role) ? Localization.changeRolePIN : Localization.setRolePIN, role.displayName))
            if role != .admin, roles.contains(role) {
                Button(Localization.remove, role: .destructive) {
                    Task { await controller.requestRemoval(for: role) }
                }
                .accessibilityLabel(String.localizedStringWithFormat(Localization.removeRolePIN, role.displayName))
            }
        }
        .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: .default))
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .fixedSize(horizontal: true, vertical: false)
        if stacked {
            VStack(alignment: .leading, spacing: metrics.spacing.medium) { details; actions }
        } else {
            HStack(spacing: metrics.spacing.medium) { details.fixedSize(); Spacer(); actions }
        }
    }

    enum Localization {
        static let title = NSLocalizedString("pos.security.title", value: "Security", comment: "POS Security settings title.")
        static let pinProtection = NSLocalizedString("pos.security.pinProtection", value: "PIN protection",
                                                     comment: "Label of the switch that turns off PIN protection.")
        static let subtitle = NSLocalizedString("pos.security.pinManagementSubtitle", value: "Manage PINs", comment: "Security settings subtitle.")
        static let protectionOff = NSLocalizedString("pos.security.protectionOff", value: "PIN protection is off. Set an Admin PIN to enable it.",
                                                    comment: "Protection status before a PIN has been set.")
        static let protectionOn = NSLocalizedString("pos.security.protectionOn", value: "PIN protection is on.",
                                                   comment: "Status shown when PIN protection is enabled.")
        static let adminOnlyExplanation = NSLocalizedString("pos.security.adminOnlyExplanation",
                                                           value: "With only an Admin PIN, every unlock has full access. Add a Cashier PIN to limit access.",
                                                           comment: "Explains the optional Cashier PIN.")
        static let rolePIN = NSLocalizedString("pos.security.rolePIN", value: "%1$@ PIN", comment: "PIN label. %1$@ is the Admin or Cashier role.")
        static let pinSet = NSLocalizedString("pos.security.pinSet", value: "PIN set", comment: "Status shown when a PIN has been set.")
        static let noPIN = NSLocalizedString("pos.security.noPIN", value: "No PIN", comment: "Status shown before a PIN has been set.")
        static let setPIN = NSLocalizedString("pos.security.setUpPIN", value: "Set up", comment: "Button to create a PIN.")
        static let setRolePIN = NSLocalizedString("pos.security.setRolePIN", value: "Set %1$@ PIN",
                                                  comment: "Set PIN accessibility label. %1$@ is the Admin or Cashier role.")
        static let changeRolePIN = NSLocalizedString("pos.security.changeRolePIN", value: "Change %1$@ PIN",
                                                     comment: "Change PIN accessibility label. %1$@ is the Admin or Cashier role.")
        static let change = NSLocalizedString("pos.security.change", value: "Change", comment: "Button to change an existing PIN.")
        static let remove = NSLocalizedString("pos.security.removePINAction", value: "Remove", comment: "Button to remove a PIN.")
        static let removeRolePIN = NSLocalizedString("pos.security.removeRolePIN", value: "Remove %1$@ PIN",
                                                     comment: "Remove PIN accessibility label. %1$@ is the Admin or Cashier role.")
        static let cancel = NSLocalizedString("pos.security.cancel", value: "Cancel", comment: "Button to cancel PIN setup or removal.")
        static let enterPIN = NSLocalizedString("pos.security.enterPIN", value: "Enter a new %1$@ PIN", comment: "%1$@ is the Admin or Cashier role.")
        static let confirmPIN = NSLocalizedString("pos.security.confirmPIN", value: "Confirm the new %1$@ PIN", comment: "%1$@ is the Admin or Cashier role.")
        static let mismatch = NSLocalizedString("pos.security.pinMismatchRetry", value: "The PINs didn’t match. Try again.",
                                               comment: "PIN confirmation mismatch.")
        static let distinctPINs = NSLocalizedString("pos.security.distinctPINs", value: "Admin and Cashier PINs must be different.",
                                                  comment: "Error shown when Admin and Cashier PINs match.")
        static let storageError = NSLocalizedString("pos.security.updatePINsError", value: "Couldn't update PINs. Try again.",
                                                   comment: "Error shown when PIN settings cannot be read or saved.")
        static let retry = NSLocalizedString("pos.security.retry", value: "Try again", comment: "Button to retry loading PIN settings.")
        static let disableProtectionReason = NSLocalizedString("pos.security.disableProtectionReason",
                                                                value: "Turning off PIN protection removes both PINs. POS will no longer ask for a PIN.",
                                                                comment: "Explains the action requiring Admin approval before PIN protection is turned off.")
    }
}

private struct POSSecurityPINEntryModal: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.posModalDismissAction) private var dismissModal
    @State private var setup: POSPINSetupController

    let role: POSLocalRole
    let controller: POSSecuritySettingsController
    let close: () -> Void

    private typealias Localization = POSSecuritySettingsView.Localization

    init(role: POSLocalRole, controller: POSSecuritySettingsController, close: @escaping () -> Void) {
        self.role = role
        self.controller = controller
        self.close = close
        self._setup = State(initialValue: controller.makePINSetupController(for: role))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: metrics.spacing.medium) {
                Text(String.localizedStringWithFormat(setup.isConfirmingPIN ? Localization.confirmPIN : Localization.enterPIN, role.displayName))
                    .font(.posBodyLargeBold)
                    .accessibilityAddTraits(.isHeader)
                if setup.hasMismatch { Text(Localization.mismatch).foregroundStyle(Color.posError).font(.posBodyMediumRegular()) }
                POSPINEntryView(state: setup.isSaving ? .loading : .idle) { pin in
                    let result = await setup.submit(pin)
                    if result == .saved { close() }
                    return result != .rejected
                }
                .id(setup.isConfirmingPIN)
                if let error = controller.error {
                    Text(error == .pinMatchesOtherRole ? Localization.distinctPINs : Localization.storageError)
                        .foregroundStyle(Color.posError).font(.posBodyMediumRegular())
                }
            }
            .frame(maxWidth: POSPINEntryView.contentWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .posModalCloseButton(action: {
            if setup.cancel() { close() }
        }, accessibilityLabel: Localization.cancel)
        .posModalSizing(fullScreenWhenCompact: true)
        .posInteractiveDismissDisabled(setup.isSaving)
        .disabled(setup.isSaving)
        .onChange(of: controller.isVisible) { _, isVisible in
            if !isVisible { dismissModal?() }
        }
        .onDisappear { setup.discardDraft() }
        .accessibilityIdentifier("pos-security-pin-entry")
    }
}

#if DEBUG
#Preview("Security on iPad") {
    POSSecuritySettingsView(controller: POSSecuritySettingsController(store: POSLocalPINStore(siteID: 0),
                                                                     session: UnrestrictedPOSAccessSession()))
        .disabled(true)
}
#endif
