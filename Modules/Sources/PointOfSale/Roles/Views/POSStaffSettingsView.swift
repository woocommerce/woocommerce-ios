import SwiftUI

// MARK: - Mode & Data Types

enum POSStaffSettingsMode {
    case local(pinService: POSPINService)
    case remote(staffMembers: [StaffMemberInfo], manageURL: URL)
}

struct StaffMemberInfo: Identifiable {
    let id: Int64
    let displayName: String
    let role: String
    let hasPIN: Bool
}

// MARK: - View

struct POSStaffSettingsView: View {
    let mode: POSStaffSettingsMode

    var body: some View {
        switch mode {
        case .local(let pinService):
            POSStaffSettingsLocalView(pinService: pinService)
        case .remote(let staffMembers, let manageURL):
            POSStaffSettingsRemoteView(staffMembers: staffMembers, manageURL: manageURL)
        }
    }
}

// MARK: - Local Mode View

private struct POSStaffSettingsLocalView: View {
    let pinService: POSPINService

    @AppStorage("com.woocommerce.pos.pinAccessEnabled") private var pinAccessEnabled: Bool = false

    @State private var showPINEntry: Bool = false
    @State private var pinEntryRole: PINRole = .manager
    @State private var pinEntryState: POSPINEntryState = .idle

    @State private var ownerPINSet: Bool = false
    @State private var cashierPINSet: Bool = false

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.staffAndSecurityTitle)
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    pinAccessToggleCard

                    if pinAccessEnabled {
                        pinManagementCard
                    }

                    footerText
                }
                .padding(.horizontal, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .onAppear {
            refreshPINStatus()
        }
        .posModal(isPresented: $showPINEntry) {
            pinEntryModal
        }
    }
}

// MARK: - Local Mode Subviews

private extension POSStaffSettingsLocalView {
    var pinAccessToggleCard: some View {
        POSInformationCard {
            POSInformationCardFieldRowWithToggle(
                label: Localization.pinAccessLabel,
                value: Localization.pinAccessDescription,
                showSeparator: false,
                isOn: $pinAccessEnabled
            )
            .onChange(of: pinAccessEnabled) { _, newValue in
                handlePINAccessToggleChanged(newValue)
            }
        }
    }

    @ViewBuilder
    var pinManagementCard: some View {
        POSInformationCard {
            VStack(spacing: POSSpacing.small) {
                ownerPINRow

                if ownerPINSet {
                    Divider()
                        .padding(.vertical, POSPadding.small)
                    cashierPINRow
                }
            }
        }
    }

    var ownerPINRow: some View {
        pinRow(
            label: Localization.ownerPINLabel,
            description: Localization.ownerPINDescription,
            isPINSet: ownerPINSet,
            role: .manager
        )
    }

    var cashierPINRow: some View {
        pinRow(
            label: Localization.cashierPINLabel,
            description: Localization.cashierPINDescription,
            isPINSet: cashierPINSet,
            role: .cashier
        )
    }

    func pinRow(label: String,
                description: String,
                isPINSet: Bool,
                role: PINRole) -> some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            VStack(alignment: .leading, spacing: POSPadding.small) {
                Text(label)
                    .font(.posBodyMediumBold)
                    .foregroundStyle(Color.posOnSurface)

                HStack(spacing: POSSpacing.xSmall) {
                    Image(systemName: "info.circle")
                        .font(.posBodySmallRegular())
                        .foregroundStyle(.secondary)
                    Text(description)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(isPINSet ? Localization.changeButton : Localization.setButton) {
                presentPINEntry(for: role)
            }
            .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: .default))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var footerText: some View {
        Text(Localization.localFooter)
            .font(.posBodyMediumRegular())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, POSPadding.small)
    }

    func confirmationBanner(message: String) -> some View {
        HStack(spacing: POSSpacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.posSuccess)
            Text(message)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .transition(.opacity)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    var pinEntryModal: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            POSPINEntryView(
                title: pinEntryTitle,
                subtitle: Localization.pinEntrySubtitle,
                state: $pinEntryState,
                onPINEntered: { pin in
                    handlePINEntered(pin)
                },
                onCancel: {
                    dismissPINEntry()
                }
            )
        }
        .padding(POSPadding.xLarge)
        .frame(maxWidth: Constants.pinEntryModalMaxWidth)
    }
}

// MARK: - Local Mode Logic

private extension POSStaffSettingsLocalView {
    var pinEntryTitle: String {
        switch pinEntryRole {
        case .manager:
            return ownerPINSet ? Localization.changeOwnerPINTitle : Localization.setOwnerPINTitle
        case .cashier:
            return cashierPINSet ? Localization.changeCashierPINTitle : Localization.setCashierPINTitle
        }
    }

    func handlePINAccessToggleChanged(_ enabled: Bool) {
        if enabled {
            presentPINEntry(for: .manager)
        } else {
            clearAllPINsAndUnlock()
        }
    }

    func clearAllPINsAndUnlock() {
        pinService.deletePIN(for: .manager)
        pinService.deletePIN(for: .cashier)
        refreshPINStatus()
    }

    func presentPINEntry(for role: PINRole) {
        pinEntryRole = role
        pinEntryState = .idle
        showPINEntry = true
    }

    func dismissPINEntry() {
        showPINEntry = false
        if !ownerPINSet && pinAccessEnabled {
            pinAccessEnabled = false
        }
    }

    func handlePINEntered(_ pin: String) {
        guard pinService.isValidFormat(pin) else {
            pinEntryState = .error(message: Localization.invalidPINError)
            return
        }

        pinService.setPIN(pin, for: pinEntryRole)
        refreshPINStatus()
        dismissPINEntry()
    }

    func refreshPINStatus() {
        ownerPINSet = pinService.hasPIN(for: .manager)
        cashierPINSet = pinService.hasPIN(for: .cashier)
    }
}

// MARK: - Remote Mode View

private struct POSStaffSettingsRemoteView: View {
    @Environment(\.posExternalViews) private var externalViews
    @Environment(\.posPermissions) private var permissions

    let staffMembers: [StaffMemberInfo]
    let manageURL: URL

    @State private var showManageStaff: Bool = false
    @State private var showManagerOverride: Bool = false
    @State private var managerOverrideState: POSManagerOverrideState = .awaitingPIN

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.staffTitle)
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    staffListCard
                    manageStaffCard
                    footerText
                }
                .padding(.horizontal, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .posFullScreenCover(isPresented: $showManageStaff) {
            externalViews.createAuthenticatedWebView(
                url: manageURL,
                title: Localization.manageStaffWebTitle,
                completion: {
                    showManageStaff = false
                }
            )
        }
        .posModal(isPresented: $showManagerOverride) {
            POSManagerOverrideView(
                actionDescription: Localization.manageStaffOverrideDescription,
                capability: POSCapability.posManageSettings.rawValue,
                overrideState: $managerOverrideState,
                onPINEntered: { pin in
                    Task { @MainActor in
                        await handleManagerOverridePIN(pin)
                    }
                },
                onCancelled: {
                    showManagerOverride = false
                }
            )
        }
    }
}

// MARK: - Remote Mode Subviews

private extension POSStaffSettingsRemoteView {
    var staffListCard: some View {
        POSInformationCard {
            VStack(spacing: POSSpacing.none) {
                ForEach(Array(staffMembers.enumerated()), id: \.element.id) { index, member in
                    staffRow(member: member)

                    if index < staffMembers.count - 1 {
                        Divider()
                            .padding(.vertical, POSPadding.small)
                    }
                }
            }
        }
    }

    func staffRow(member: StaffMemberInfo) -> some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                Text(member.displayName)
                    .font(.posBodyMediumBold)
                    .foregroundStyle(Color.posOnSurface)
                Text(member.role)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            pinStatusBadge(hasPIN: member.hasPIN)
        }
        .padding(.vertical, POSPadding.xSmall)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func pinStatusBadge(hasPIN: Bool) -> some View {
        if hasPIN {
            HStack(spacing: POSSpacing.small) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.posSuccess)
                Text(Localization.pinSetLabel)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(.secondary)
            }
        } else {
            HStack(spacing: POSSpacing.small) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.posAlert)
                Text(Localization.noPINLabel)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(.secondary)
            }
        }
    }

    var manageStaffCard: some View {
        Button {
            handleManageStaffTapped()
        } label: {
            Text(Localization.manageStaffButton)
        }
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        .frame(maxWidth: .infinity)
    }

    var footerText: some View {
        Text(Localization.remoteFooter)
            .font(.posBodyMediumRegular())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, POSPadding.small)
    }
}

// MARK: - Remote Mode Logic

private extension POSStaffSettingsRemoteView {
    func handleManageStaffTapped() {
        let result = permissions.checkPermission(.posManageSettings)
        switch result {
        case .allowed:
            showManageStaff = true
        case .requiresOverride:
            managerOverrideState = .awaitingPIN
            showManagerOverride = true
        }
    }

    func handleManagerOverridePIN(_ pin: String) async {
        do {
            _ = try await permissions.requestManagerApproval(
                managerPIN: pin,
                for: .posManageSettings,
                orderID: nil
            )
            managerOverrideState = .approved
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showManagerOverride = false
                showManageStaff = true
            }
        } catch {
            managerOverrideState = .error(message: (error as? LocalizedError)?.errorDescription ?? Localization.invalidPIN)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let pinEntryModalMaxWidth: CGFloat = 500
    static let confirmationDismissDelay: TimeInterval = 3.0
}

// MARK: - Localization

private enum Localization {
    // MARK: Common
    static let staffTitle = NSLocalizedString(
        "posStaffSettingsView.staffTitle",
        value: "Staff",
        comment: "Navigation title for the staff settings detail view in POS settings."
    )

    // MARK: Local Mode
    static let staffAndSecurityTitle = NSLocalizedString(
        "posStaffSettingsView.staffAndSecurityTitle",
        value: "Staff & Security",
        comment: "Navigation title for the local staff and security settings in POS."
    )

    static let pinAccessLabel = NSLocalizedString(
        "posStaffSettingsView.pinAccessLabel",
        value: "PIN access",
        comment: "Toggle label to enable or disable PIN access in POS staff settings."
    )

    static let pinAccessDescription = NSLocalizedString(
        "posStaffSettingsView.pinAccessDescription",
        value: "When enabled, POS can be locked and staff use PINs to access the register.",
        comment: "Description of the PIN access toggle in POS staff settings."
    )

    static let ownerPINLabel = NSLocalizedString(
        "posStaffSettingsView.ownerPINLabel",
        value: "Owner PIN",
        comment: "Label for the owner PIN row in POS staff settings."
    )

    static let ownerPINDescription = NSLocalizedString(
        "posStaffSettingsView.ownerPINDescription",
        value: "Full access to all POS features and can approve restricted actions",
        comment: "Description of the owner PIN role in POS staff settings."
    )

    static let cashierPINLabel = NSLocalizedString(
        "posStaffSettingsView.cashierPINLabel",
        value: "Cashier PIN",
        comment: "Label for the cashier PIN row in POS staff settings."
    )

    static let cashierPINDescription = NSLocalizedString(
        "posStaffSettingsView.cashierPINDescription",
        value: "Process sales and payments. Refunds and settings require owner approval",
        comment: "Description of the cashier PIN role in POS staff settings."
    )

    static let setButton = NSLocalizedString(
        "posStaffSettingsView.setButton",
        value: "Set",
        comment: "Button title to set a new PIN for a role in POS staff settings."
    )

    static let changeButton = NSLocalizedString(
        "posStaffSettingsView.changeButton",
        value: "Change",
        comment: "Button title to change an existing PIN for a role in POS staff settings."
    )

    static let pinEntrySubtitle = NSLocalizedString(
        "posStaffSettingsView.pinEntrySubtitle",
        value: "Enter a 4-digit PIN",
        comment: "Subtitle shown in the PIN entry modal when setting or changing a PIN."
    )

    static let setOwnerPINTitle = NSLocalizedString(
        "posStaffSettingsView.setOwnerPINTitle",
        value: "Set Owner PIN",
        comment: "Title for the PIN entry modal when setting the owner PIN."
    )

    static let changeOwnerPINTitle = NSLocalizedString(
        "posStaffSettingsView.changeOwnerPINTitle",
        value: "Change Owner PIN",
        comment: "Title for the PIN entry modal when changing the owner PIN."
    )

    static let setCashierPINTitle = NSLocalizedString(
        "posStaffSettingsView.setCashierPINTitle",
        value: "Set Cashier PIN",
        comment: "Title for the PIN entry modal when setting the cashier PIN."
    )

    static let changeCashierPINTitle = NSLocalizedString(
        "posStaffSettingsView.changeCashierPINTitle",
        value: "Change Cashier PIN",
        comment: "Title for the PIN entry modal when changing the cashier PIN."
    )

    static let invalidPINError = NSLocalizedString(
        "posStaffSettingsView.invalidPINError",
        value: "PIN must be 4-6 digits",
        comment: "Error message shown when an invalid PIN format is entered in POS staff settings."
    )

    static let pinSetConfirmationFormat = NSLocalizedString(
        "posStaffSettingsView.pinUpdatedConfirmationFormat",
        value: "%1$@ PIN has been updated",
        comment: "Confirmation message after successfully setting a PIN. %1$@ is the role name (Owner or Cashier)."
    )

    static let ownerRoleName = NSLocalizedString(
        "posStaffSettingsView.ownerRoleName",
        value: "Owner",
        comment: "Role name used in the PIN confirmation message for the owner role."
    )

    static let cashierRoleName = NSLocalizedString(
        "posStaffSettingsView.cashierRoleName",
        value: "Cashier",
        comment: "Role name used in the PIN confirmation message for the cashier role."
    )

    static let localFooter = NSLocalizedString(
        "posStaffSettingsView.localAutoLockFooter",
        value: "POS locks when you tap Lock POS from the menu, or automatically after 5 minutes of inactivity.",
        comment: "Footer text explaining how POS locking works in local mode, including auto-lock timeout."
    )

    // MARK: Remote Mode
    static let pinSetLabel = NSLocalizedString(
        "posStaffSettingsView.pinSetLabel",
        value: "PIN set",
        comment: "Status label shown next to a staff member who has a PIN configured."
    )

    static let noPINLabel = NSLocalizedString(
        "posStaffSettingsView.noPINLabel",
        value: "No PIN",
        comment: "Status label shown next to a staff member who does not have a PIN configured."
    )

    static let manageStaffButton = NSLocalizedString(
        "posStaffSettingsView.manageStaffWebButton",
        value: "Manage staff on the web",
        comment: "Button to open the WordPress admin staff management page in a web view."
    )

    static let manageStaffWebTitle = NSLocalizedString(
        "posStaffSettingsView.manageStaffWebTitle",
        value: "Manage Staff",
        comment: "Navigation title for the web view showing WordPress admin staff management."
    )

    static let manageStaffOverrideDescription = NSLocalizedString(
        "posStaffSettingsView.manageStaffOverrideDescription",
        value: "Open WordPress admin staff management",
        comment: "Description of the action shown in the manager override modal when opening wp-admin."
    )

    static let invalidPIN = NSLocalizedString(
        "posStaffSettingsView.invalidPIN",
        value: "Invalid PIN",
        comment: "Error message shown when an incorrect manager PIN is entered for override."
    )

    static let remoteFooter = NSLocalizedString(
        "posStaffSettingsView.remoteAutoLockFooter",
        value: "POS locks when you tap Lock POS from the menu, or automatically after 5 minutes of inactivity.",
        comment: "Footer text explaining how POS locking works in remote mode, including auto-lock timeout."
    )
}

// MARK: - Previews

#if DEBUG
#Preview("Local - PIN Off") {
    POSStaffSettingsView(mode: .local(pinService: POSPINService(storage: InMemoryPINStorage())))
}

#Preview("Local - PINs Set") {
    let storage = InMemoryPINStorage()
    let service = POSPINService(storage: storage)
    service.setPIN("1234", for: .manager)
    service.setPIN("5678", for: .cashier)
    return POSStaffSettingsView(mode: .local(pinService: service))
}

#Preview("Remote - Staff List") {
    let members: [StaffMemberInfo] = [
        StaffMemberInfo(id: 1, displayName: "Alice", role: "Administrator", hasPIN: true),
        StaffMemberInfo(id: 2, displayName: "Bob", role: "POS Manager", hasPIN: true),
        StaffMemberInfo(id: 3, displayName: "Carol", role: "POS Cashier", hasPIN: false),
        StaffMemberInfo(id: 4, displayName: "Dave", role: "Shop Manager", hasPIN: false)
    ]
    return POSStaffSettingsView(
        mode: .remote(
            staffMembers: members,
            manageURL: URL(string: "https://example.com/wp-admin/admin.php?page=wc-settings&tab=point-of-sale&section=staff")!
        )
    )
}
#endif
