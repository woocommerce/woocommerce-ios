import SwiftUI

struct POSSecuritySettingsView: View {
    @Environment(\.posMetrics) private var metrics
    let controller: POSSecuritySettingsController
    @State private var editing: POSLocalRole?
    @State private var confirmRemoval = false

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            POSPageHeaderView(title: Localization.title)
            ScrollView {
                VStack(alignment: .leading, spacing: metrics.spacing.medium) {
                    if let roles = controller.roles {
                        Text(roles.contains(.admin) ? Localization.protectionOn : Localization.protectionOff)
                            .font(.posBodyMediumRegular())
                        POSInformationCard {
                            ViewThatFits(in: .horizontal) {
                                pinRows(roles, stacked: false)
                                pinRows(roles, stacked: true)
                            }
                        }
                        if roles == [.admin] { Text(Localization.adminOnlyExplanation).font(.posBodyMediumRegular()) }
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
        .onDisappear { editing = nil }
        .posModal(isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } }), onDismiss: { controller.load() }) {
            if let role = editing {
                POSSecurityPINEntryModal(role: role, controller: controller, close: { editing = nil })
            }
        }
        .alert(Localization.removeAdmin, isPresented: $confirmRemoval) {
            Button(Localization.remove, role: .destructive) { Task { await controller.save(nil, for: .admin) } }
            Button(Localization.cancel, role: .cancel) {}
        } message: { Text(Localization.removalMessage) }
        .accessibilityIdentifier("pos-security-settings")
    }

    private func pinRows(_ roles: Set<POSLocalRole>, stacked: Bool) -> some View {
        VStack(spacing: metrics.spacing.medium) {
            pinRow(.admin, roles: roles, stacked: stacked)
            if roles.contains(.admin) {
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
            if roles.contains(role) {
                Button(Localization.remove, role: .destructive) {
                    if role == .admin { confirmRemoval = true } else { Task { await controller.save(nil, for: role) } }
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
        static let subtitle = NSLocalizedString("pos.security.subtitle", value: "Manage local PINs", comment: "Security settings subtitle.")
        static let protectionOff = NSLocalizedString("pos.security.protectionOff", value: "PIN protection is off. Set an Admin PIN to enable it.",
                                                    comment: "Protection status before local PIN setup.")
        static let protectionOn = NSLocalizedString("pos.security.protectionOn", value: "PIN protection is on.", comment: "Local PIN protection status.")
        static let adminOnlyExplanation = NSLocalizedString("pos.security.adminOnlyExplanation",
                                                           value: "With only an Admin PIN, every unlock has full access. Add a Cashier PIN to limit access.",
                                                           comment: "Explains the optional Cashier PIN.")
        static let rolePIN = NSLocalizedString("pos.security.rolePIN", value: "%1$@ PIN", comment: "PIN label. %1$@ is the Admin or Cashier role.")
        static let pinSet = NSLocalizedString("pos.security.pinSet", value: "PIN set", comment: "Local PIN status.")
        static let noPIN = NSLocalizedString("pos.security.noPIN", value: "No PIN", comment: "Local PIN status before setup.")
        static let setPIN = NSLocalizedString("pos.security.setUpPIN", value: "Set up", comment: "Set up a local PIN button.")
        static let setRolePIN = NSLocalizedString("pos.security.setRolePIN", value: "Set %1$@ PIN",
                                                  comment: "Set PIN accessibility label. %1$@ is the Admin or Cashier role.")
        static let changeRolePIN = NSLocalizedString("pos.security.changeRolePIN", value: "Change %1$@ PIN",
                                                     comment: "Change PIN accessibility label. %1$@ is the Admin or Cashier role.")
        static let change = NSLocalizedString("pos.security.change", value: "Change", comment: "Change a local PIN button.")
        static let remove = NSLocalizedString("pos.security.removePINAction", value: "Remove", comment: "Remove a local PIN button.")
        static let removeRolePIN = NSLocalizedString("pos.security.removeRolePIN", value: "Remove %1$@ PIN",
                                                     comment: "Remove PIN accessibility label. %1$@ is the Admin or Cashier role.")
        static let cancel = NSLocalizedString("pos.security.cancel", value: "Cancel", comment: "Cancel local PIN setup or removal.")
        static let enterPIN = NSLocalizedString("pos.security.enterPIN", value: "Enter a new %1$@ PIN", comment: "%1$@ is the Admin or Cashier role.")
        static let confirmPIN = NSLocalizedString("pos.security.confirmPIN", value: "Confirm the new %1$@ PIN", comment: "%1$@ is the Admin or Cashier role.")
        static let mismatch = NSLocalizedString("pos.security.pinMismatchRetry", value: "The PINs didn’t match. Try again.", comment: "PIN confirmation mismatch.")
        static let distinctPINs = NSLocalizedString("pos.security.distinctPINs", value: "Admin and Cashier PINs must be different.",
                                                  comment: "Error when local role PINs match.")
        static let storageError = NSLocalizedString("pos.security.storageError", value: "Couldn't update local PINs. Try again.",
                                                   comment: "Local PIN storage error.")
        static let retry = NSLocalizedString("pos.security.retry", value: "Try again", comment: "Retry loading local PIN settings.")
        static let removeAdmin = NSLocalizedString("pos.security.removeAdmin", value: "Remove Admin PIN?", comment: "Confirm Admin PIN removal title.")
        static let removalMessage = NSLocalizedString("pos.security.removalMessage",
                                                     value: "This removes both local PINs and turns off PIN protection on this device.",
                                                     comment: "Explains Admin PIN removal.")
    }
}

private struct POSSecurityPINEntryModal: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.posModalDismissAction) private var dismissModal
    @State private var firstPIN: String?
    @State private var mismatch = false

    let role: POSLocalRole
    let controller: POSSecuritySettingsController
    let close: () -> Void

    private typealias Localization = POSSecuritySettingsView.Localization

    var body: some View {
        ScrollView {
            VStack(spacing: metrics.spacing.medium) {
                Text(String.localizedStringWithFormat(firstPIN == nil ? Localization.enterPIN : Localization.confirmPIN, role.displayName))
                    .font(.posBodyLargeBold)
                    .accessibilityAddTraits(.isHeader)
                if mismatch { Text(Localization.mismatch).foregroundStyle(Color.posError).font(.posBodyMediumRegular()) }
                POSPINEntryView(state: controller.isSaving ? .loading : .idle) { pin in
                    guard let firstPIN else { mismatch = false; self.firstPIN = pin; return true }
                    guard firstPIN == pin else { self.firstPIN = nil; mismatch = true; return false }
                    let saved = await controller.save(pin, for: role)
                    if saved { close() }
                    self.firstPIN = nil
                    return saved
                }
                .id(firstPIN == nil)
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
            guard !controller.isSaving else { return }
            close()
        }, accessibilityLabel: Localization.cancel)
        .posModalSizing(fullScreenWhenCompact: true)
        .posInteractiveDismissDisabled(controller.isSaving)
        .disabled(controller.isSaving)
        .onChange(of: controller.isVisible) { _, isVisible in
            if !isVisible { dismissModal?() }
        }
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
