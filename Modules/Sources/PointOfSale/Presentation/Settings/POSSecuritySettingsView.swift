import SwiftUI

struct POSSecuritySettingsView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var modalManager: POSModalManager
    let controller: POSSecuritySettingsController
    @State private var presentation = POSSecurityPINPresentation()
    @State private var approval = POSManagerOverrideHandler()
    @State private var approvalTask: Task<Void, Never>?
    @State private var isGuidedAccessActive = UIAccessibility.isGuidedAccessEnabled

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            if controller.roles?.isEmpty == true {
                POSAccessControlSetupView {
                    controller.load()
                    presentation.present(.editor(controller.makePINSetupFlow(for: .admin)))
                }
                .overlay(alignment: .top) {
                    if horizontalSizeClass == .compact {
                        POSPageHeaderView(title: "")
                            .background(Color.posSurface)
                    }
                }
            } else {
                POSPageHeaderView(title: Localization.title)
                ScrollView {
                    VStack(alignment: .leading, spacing: metrics.spacing.medium) {
                        if controller.roles != nil {
                            pinProtectionCard
                            lockSettingsCard(controller.lockPreferences)
                            deviceSecurityCard
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
                    .posPadding(.bottom, \.medium)
                }
            }
        }
        .background(Color.posSurface)
        .foregroundStyle(Color.posOnSurface)
        .disabled(controller.isSaving || presentation.isTransitioning)
        .onAppear {
            controller.load()
            isGuidedAccessActive = UIAccessibility.isGuidedAccessEnabled
            if controller.guidedAccessGuide != nil {
                presentation.present(.guidedAccessGuide)
            }
        }
        .onDisappear(perform: endEditing)
        .onChange(of: approval.request) { _, request in
            if let request {
                presentation.present(.approval(request))
            } else {
                presentation.approvalEnded()
            }
        }
        .onChange(of: controller.isVisible) { _, isVisible in
            if !isVisible {
                endEditing()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.guidedAccessStatusDidChangeNotification)) { _ in
            isGuidedAccessActive = UIAccessibility.isGuidedAccessEnabled
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            isGuidedAccessActive = UIAccessibility.isGuidedAccessEnabled
        }
        .posModal(item: presentationBinding,
                  compactStyle: presentation.destination?.compactStyle ?? .fullScreen(title: Localization.title),
                  onDismissCompleted: { destination in
                      guard controller.isVisible else { endEditing(); return }
                      presentation.dismissalCompleted(for: destination)
                  }) { destination in
            switch destination {
            case .approval(let request):
                POSManagerOverrideView(handler: approval, request: request)
                    .posManagerOverrideModalSizing()
            case .editor(let flow):
                POSPINSetupFlowView(flow: flow, controller: controller, close: closeEditor) {
                    startGuidedAccessGuide(afterDismissing: flow)
                }
            case .guidedAccessGuide:
                if let guide = controller.guidedAccessGuide {
                    POSGuidedAccessGuideView(guide: guide, close: closeGuidedAccessGuide)
                }
            }
        }
        .accessibilityIdentifier("pos-security-settings")
    }

    private var presentationBinding: Binding<POSSecurityPINPresentation.Destination?> {
        Binding(get: { presentation.destination }, set: { newValue in
            guard newValue == nil else { return }
            switch presentation.destination {
            case .editor: closeEditor()
            case .approval:
                presentation.cancel()
                dismissApproval()
            case .guidedAccessGuide:
                closeGuidedAccessGuide()
            case nil: break
            }
        })
    }

    private func endEditing() {
        if case .guidedAccessGuide? = presentation.destination {
            // This cover reuses its modal manager after a lock; finish guide ownership before it detaches.
            modalManager.onDisappear()
        }
        presentation.cancel()
        controller.endPINEditing()
        controller.dismissGuidedAccessGuide()
        dismissApproval()
    }

    private func startGuidedAccessGuide() {
        controller.startGuidedAccessGuide()
        if controller.guidedAccessGuide != nil {
            presentation.present(.guidedAccessGuide)
        }
    }

    private func startGuidedAccessGuide(afterDismissing editor: POSPINSetupFlow) {
        guard presentation.dismissEditorForGuide(editor) else {
            return
        }
        controller.endPINEditing()
        controller.load()
        controller.startGuidedAccessGuide()
    }

    private func closeGuidedAccessGuide() {
        controller.closeGuidedAccessGuide()
        presentation.cancel()
    }

    private func closeEditor() {
        presentation.cancel()
        controller.endPINEditing()
        controller.load()
    }

    private var pinProtectionCard: some View {
        securityCard(title: Localization.pinProtection) {
            POSSecuritySettingRow(title: Localization.enableProtection, subtitle: Localization.enableProtectionDetail) { _ in
                toggle(Localization.enableProtection, isOn: protectionBinding)
            }
            Divider()
            pinRow(.admin)
            if controller.offersCashierPINSetup {
                Divider()
                pinRow(.cashier)
            }
            // WOOMOB-4591 links the roles documentation.
            Button(Localization.learnMore) {}
                .buttonStyle(.plain)
                .font(.posBodyMediumRegular(underline: true))
                .foregroundStyle(Color.posPrimary)
        }
    }

    private func lockSettingsCard(_ preferences: POSLockPreferences) -> some View {
        securityCard(title: Localization.lockSettings) {
            lockToggleRow(Localization.lockWhenPOSOpens, \.locksWhenPOSOpens, in: preferences)
            Divider()
            lockToggleRow(Localization.lockInBackground, \.locksInBackground, in: preferences)
            Divider()
            lockToggleRow(Localization.lockAfterSale, \.locksAfterSale, in: preferences)
            Divider()
            POSSecuritySettingRow(title: Localization.lockAfterInactivity) { _ in
                inactivityMenu(selected: preferences.inactivityTimeout)
            }
        }
    }

    private var deviceSecurityCard: some View {
        securityCard(title: Localization.deviceSecurity) {
            POSSecuritySettingRow(title: Localization.guidedAccess, subtitle: Localization.guidedAccessDetail) { _ in
                if isGuidedAccessActive {
                    Label(Localization.active, systemImage: "checkmark")
                        .labelStyle(POSTrailingIconLabelStyle())
                        .font(.posCaptionRegular)
                        .foregroundStyle(Color.posOnDefault)
                        .posPadding(.horizontal, \.small)
                        .posPadding(.vertical, \.xSmall)
                        .background(Color.posDefault)
                        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                } else {
                    Button(Localization.setUpGuidedAccessButton, action: startGuidedAccessGuide)
                        .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: .primary))
                        .accessibilityLabel(Localization.setUpGuidedAccess)
                }
            }
        }
    }

    private func securityCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        POSInformationCard {
            VStack(alignment: .leading, spacing: metrics.spacing.medium) {
                Text(title)
                    .font(.posBodyLargeBold)
                    .accessibilityAddTraits(.isHeader)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func pinRow(_ role: POSLocalRole) -> some View {
        let actions = controller.pinActions(for: role)
        POSSecuritySettingRow(title: String.localizedStringWithFormat(Localization.rolePIN, role.displayName),
                              subtitle: role == .admin ? Localization.adminDetail : Localization.cashierDetail) { isStacked in
            if actions.count > 1, !isStacked {
                POSMenu {
                    ForEach(actions, id: \.self) { action in
                        POSMenuButton(role: action == .delete ? .destructive : nil, action: { perform(action, for: role) }) {
                            Label(title(for: action), systemImage: action == .delete ? "trash" : "square.and.pencil")
                        }
                        .accessibilityLabel(accessibilityLabel(for: action, role: role))
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.posBodyLargeBold)
                        .foregroundStyle(Color.posOnSurface)
                        .posPadding(\.small)
                }
                .accessibilityLabel(String.localizedStringWithFormat(Localization.roleActions, role.displayName))
            } else {
                HStack(spacing: metrics.spacing.small) {
                    ForEach(actions, id: \.self) { action in
                        pinButton(action, for: role)
                    }
                }
            }
        }
    }

    private func pinButton(_ action: POSPINAction, for role: POSLocalRole) -> some View {
        Button(role: action == .delete ? .destructive : nil, action: { perform(action, for: role) }) {
            Text(title(for: action))
                .if(action == .delete) { $0.foregroundStyle(Color.posError) }
        }
        .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: action == .setUp ? .primary : .default))
        .accessibilityLabel(accessibilityLabel(for: action, role: role))
    }

    private func inactivityMenu(selected: POSInactivityLockTimeout) -> some View {
        let rowSpacing = metrics.spacing.medium
        let controller = controller
        return POSMenu {
            ForEach(POSInactivityLockTimeout.allCases, id: \.self) { timeout in
                POSMenuButton(action: { controller.updateLockPreferences { $0.inactivityTimeout = timeout } }) {
                    HStack(spacing: rowSpacing) {
                        Text(Self.title(for: timeout))
                        Spacer()
                        if timeout == selected {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .accessibilityAddTraits(timeout == selected ? .isSelected : [])
            }
        } label: {
            Label(Self.title(for: selected), systemImage: "chevron.up.chevron.down")
                .labelStyle(POSTrailingIconLabelStyle())
                .font(.posBodyMediumBold)
                .foregroundStyle(Color.posOnSurface)
        }
        .accessibilityLabel(Localization.lockAfterInactivity)
        .accessibilityValue(Self.title(for: selected))
    }

    private func lockToggleRow(_ title: String,
                               _ keyPath: WritableKeyPath<POSLockPreferences, Bool>,
                               in preferences: POSLockPreferences) -> some View {
        POSSecuritySettingRow(title: title) { _ in
            toggle(title, isOn: Binding(get: { preferences[keyPath: keyPath] }, set: { value in
                controller.updateLockPreferences { $0[keyPath: keyPath] = value }
            }))
        }
    }

    private func toggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle())
            .tint(Color.posPrimaryContainer)
    }

    private var protectionBinding: Binding<Bool> {
        Binding(get: { controller.isPINProtectionEnabled }, set: { isEnabled in
            if !isEnabled {
                approvalTask?.cancel()
                approvalTask = Task {
                    _ = await controller.requestProtectionRemoval(using: approval, reason: Localization.disableProtectionReason)
                    guard !Task.isCancelled else { return }
                    presentation.finishApproval(editor: nil)
                }
            }
        })
    }

    private func dismissApproval() {
        approvalTask?.cancel()
        approvalTask = nil
        approval.cancel()
    }

    private func editPIN(for role: POSLocalRole) {
        controller.load()
        dismissApproval()
        if role == .admin, controller.roles?.contains(.admin) == true {
            approvalTask = Task {
                let flow = await controller.requestAdminPINChange(using: approval, reason: Localization.changeAdminPINReason)
                guard !Task.isCancelled else { return }
                presentation.finishApproval(editor: flow)
            }
        } else {
            presentation.present(.editor(controller.makePINSetupFlow(for: role)))
        }
    }

    private func perform(_ action: POSPINAction, for role: POSLocalRole) {
        switch action {
        case .setUp, .change:
            editPIN(for: role)
        case .delete:
            Task { await controller.requestRemoval(for: role) }
        }
    }

    private func title(for action: POSPINAction) -> String {
        switch action {
        case .setUp: Localization.setPIN
        case .change: Localization.change
        case .delete: Localization.delete
        }
    }

    private func accessibilityLabel(for action: POSPINAction, role: POSLocalRole) -> String {
        let format = switch action {
        case .setUp: Localization.setRolePIN
        case .change: Localization.changeRolePIN
        case .delete: Localization.deleteRolePIN
        }
        return String.localizedStringWithFormat(format, role.displayName)
    }

    static func title(for timeout: POSInactivityLockTimeout) -> String {
        switch timeout {
        case .never: Localization.never
        case .oneMinute: Localization.oneMinute
        default: String.localizedStringWithFormat(Localization.minutes, timeout.rawValue)
        }
    }

    enum Localization {
        static let title = NSLocalizedString("pos.security.title", value: "Security", comment: "POS Security settings title.")
        static let pinProtection = NSLocalizedString("pos.security.pinProtection", value: "PIN protection",
                                                     comment: "Title of the Security card with the PIN protection switch and PINs.")
        static let subtitle = NSLocalizedString("pos.security.pinsAndLockSubtitle", value: "Manage PINs and lock settings",
                                                comment: "Security settings subtitle.")
        static let enableProtection = NSLocalizedString("pos.security.enableProtection", value: "Enable PIN protection",
                                                        comment: "Label of the switch that turns off PIN protection.")
        static let enableProtectionDetail = NSLocalizedString("pos.security.enableProtection.detail",
                                                              value: "Require a PIN to unlock POS and access protected settings.",
                                                              comment: "Explains the PIN protection switch.")
        static let rolePIN = NSLocalizedString("pos.security.rolePIN", value: "%1$@ PIN", comment: "PIN label. %1$@ is the Admin or Cashier role.")
        static let adminDetail = NSLocalizedString("pos.security.adminPIN.detail", value: "Full access to POS and its settings.",
                                                   comment: "Explains what the Admin PIN allows.")
        static let cashierDetail = NSLocalizedString("pos.security.cashierPIN.detail", value: "Unlock POS without access to protected settings.",
                                                     comment: "Explains what the Cashier PIN allows.")
        static let learnMore = NSLocalizedString("pos.security.learnMoreAboutRoles", value: "Learn more about roles",
                                                 comment: "Link to more information about POS roles.")
        static let setPIN = NSLocalizedString("pos.security.setUpPIN", value: "Set up", comment: "Button to create a PIN.")
        static let setRolePIN = NSLocalizedString("pos.security.setRolePIN", value: "Set %1$@ PIN",
                                                  comment: "Set PIN accessibility label. %1$@ is the Admin or Cashier role.")
        static let changeRolePIN = NSLocalizedString("pos.security.changeRolePIN", value: "Change %1$@ PIN",
                                                     comment: "Change PIN accessibility label. %1$@ is the Admin or Cashier role.")
        static let change = NSLocalizedString("pos.security.change", value: "Change", comment: "Button to change an existing PIN.")
        static let delete = NSLocalizedString("pos.security.deletePINAction", value: "Delete", comment: "Menu action that deletes a PIN.")
        static let deleteRolePIN = NSLocalizedString("pos.security.deleteRolePIN", value: "Delete %1$@ PIN",
                                                     comment: "Delete PIN accessibility label. %1$@ is the Cashier role.")
        static let roleActions = NSLocalizedString("pos.security.rolePINActions", value: "%1$@ PIN actions",
                                                   comment: "Accessibility label of the menu with PIN actions. %1$@ is the Cashier role.")
        static let lockSettings = NSLocalizedString("pos.security.lockSettings", value: "Lock settings",
                                                    comment: "Title of the Security card with automatic lock settings.")
        static let lockWhenPOSOpens = NSLocalizedString("pos.security.lockWhenPOSOpens", value: "Require PIN to launch POS",
                                                        comment: "Switch that locks POS whenever it opens.")
        static let lockInBackground = NSLocalizedString("pos.security.lockInBackground", value: "Lock POS when app goes to background",
                                                        comment: "Switch that locks POS when the app goes to the background.")
        static let lockAfterSale = NSLocalizedString("pos.security.lockAfterSale", value: "Lock POS after each sale",
                                                     comment: "Switch that locks POS when a new order starts after a completed sale.")
        static let lockAfterInactivity = NSLocalizedString("pos.security.lockAfterInactivity", value: "Lock POS after",
                                                           comment: "Label of the menu that selects how long POS can be inactive before it locks.")
        static let never = NSLocalizedString("pos.security.inactivity.never", value: "Never",
                                             comment: "Inactivity lock option that never locks POS after inactivity.")
        static let oneMinute = NSLocalizedString("pos.security.inactivity.oneMinute", value: "1 minute",
                                                 comment: "Inactivity lock option of one minute.")
        static let minutes = NSLocalizedString("pos.security.inactivity.minutes", value: "%1$d minutes",
                                               comment: "Inactivity lock option. %1$d is a number of minutes greater than one.")
        static let deviceSecurity = NSLocalizedString("pos.security.deviceSecurity", value: "Device security",
                                                      comment: "Title of the Security card with device-level protections.")
        static let guidedAccess = NSLocalizedString("pos.security.guidedAccess", value: "Guided Access",
                                                    comment: "Name of the iOS Guided Access feature.")
        static let guidedAccessDetail = NSLocalizedString("pos.security.guidedAccess.detail",
                                                          value: "Prevent users from leaving POS or switching to other apps.",
                                                          comment: "Explains what Guided Access does.")
        static let setUpGuidedAccessButton = NSLocalizedString("pos.security.setUpGuidedAccess.button", value: "Set up",
                                                               comment: "Label of the Guided Access setup button in POS Security.")
        static let setUpGuidedAccess = NSLocalizedString("pos.security.setUpGuidedAccess", value: "Set up Guided Access",
                                                         comment: "Accessibility label of the button that sets up Guided Access.")
        static let active = NSLocalizedString("pos.security.guidedAccess.active", value: "Active",
                                              comment: "Badge shown while a Guided Access session is running.")
        static let mismatch = NSLocalizedString("pos.security.pinMismatchRetry", value: "The PINs didn’t match. Try again.",
                                               comment: "PIN confirmation mismatch.")
        static let distinctPINs = NSLocalizedString("pos.security.distinctPINs", value: "Admin and Cashier PINs must be different.",
                                                  comment: "Error shown when Admin and Cashier PINs match.")
        static let storageError = NSLocalizedString("pos.security.updatePINsError", value: "Couldn't update PINs. Try again.",
                                                   comment: "Error shown when PIN settings cannot be read or saved.")
        static let retry = NSLocalizedString("pos.security.retry", value: "Try again", comment: "Button to retry loading PIN settings.")
        static let changeAdminPINReason = NSLocalizedString("pos.security.changeAdminPINReason",
                                                             value: "Enter your current Admin PIN to change it.",
                                                             comment: "Explains the fresh approval required before changing the Admin PIN.")
        static let disableProtectionReason = NSLocalizedString("pos.security.disableProtectionReason",
                                                                value: "Turning off PIN protection removes both PINs. POS will no longer ask for a PIN.",
                                                                comment: "Explains the action requiring Admin approval before PIN protection is turned off.")
    }
}

private struct POSSecuritySettingRow<Accessory: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.posMetrics) private var metrics
    let title: String
    var subtitle: String?
    @ViewBuilder let accessory: (_ isStacked: Bool) -> Accessory

    var body: some View {
        Group {
            if isStacked {
                VStack(alignment: .leading, spacing: metrics.spacing.small) {
                    text
                    accessory(isStacked)
                }
            } else {
                HStack(spacing: metrics.spacing.medium) {
                    text
                    Spacer(minLength: metrics.spacing.none)
                    accessory(isStacked).fixedSize()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var isStacked: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: metrics.spacing.xSmall) {
            Text(title)
                .font(.posBodyMediumRegular())
            if let subtitle {
                Text(subtitle)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct POSTrailingIconLabelStyle: LabelStyle {
    @Environment(\.posMetrics) private var metrics

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: metrics.spacing.xSmall) {
            configuration.title
            configuration.icon
        }
    }
}

#if DEBUG
#Preview("Security on iPad") {
    POSSecuritySettingsView(controller: POSSecuritySettingsController(store: POSLocalPINStore(siteID: 0),
                                                                     session: UnrestrictedPOSAccessSession(),
                                                                     lockSettings: POSLockSettings(siteID: 0)))
        .disabled(true)
}
#endif
