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

    @AppStorage("com.woocommerce.pos.passcodesEnabled") private var passcodesEnabled: Bool = false

    @State private var showPINEntry: Bool = false
    @State private var pinEntryRole: PINRole = .manager
    @State private var pinEntryState: POSPINEntryState = .idle
    @State private var confirmationMessage: String?

    @State private var ownerPINSet: Bool = false
    @State private var cashierPINSet: Bool = false

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.staffAndSecurityTitle)
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    passcodesToggleCard

                    if passcodesEnabled {
                        pinManagementCard
                    }

                    if let confirmationMessage {
                        confirmationBanner(message: confirmationMessage)
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
    var passcodesToggleCard: some View {
        POSInformationCard {
            POSInformationCardFieldRowWithToggle(
                label: Localization.passcodesLabel,
                value: Localization.passcodesDescription,
                showSeparator: false,
                isOn: $passcodesEnabled
            )
            .onChange(of: passcodesEnabled) { _, newValue in
                handlePasscodesToggleChanged(newValue)
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
            label: Localization.ownerPasscodeLabel,
            description: Localization.ownerPasscodeDescription,
            isPINSet: ownerPINSet,
            role: .manager
        )
    }

    var cashierPINRow: some View {
        pinRow(
            label: Localization.cashierPasscodeLabel,
            description: Localization.cashierPasscodeDescription,
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
            return ownerPINSet ? Localization.changeOwnerPasscodeTitle : Localization.setOwnerPasscodeTitle
        case .cashier:
            return cashierPINSet ? Localization.changeCashierPasscodeTitle : Localization.setCashierPasscodeTitle
        }
    }

    func handlePasscodesToggleChanged(_ enabled: Bool) {
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
        if !ownerPINSet && passcodesEnabled {
            passcodesEnabled = false
        }
    }

    func handlePINEntered(_ pin: String) {
        guard pinService.isValidFormat(pin) else {
            pinEntryState = .error(message: Localization.invalidPINError)
            return
        }

        pinService.setPIN(pin, for: pinEntryRole)
        dismissPINEntry()
        refreshPINStatus()

        let roleName = pinEntryRole == .manager ? Localization.ownerRoleName : Localization.cashierRoleName
        withAnimation {
            confirmationMessage = String(format: Localization.pinSetConfirmationFormat, roleName)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.confirmationDismissDelay) {
            withAnimation {
                confirmationMessage = nil
            }
        }
    }

    func refreshPINStatus() {
        ownerPINSet = pinService.hasPIN(for: .manager)
        cashierPINSet = pinService.hasPIN(for: .cashier)
    }
}

// MARK: - Remote Mode View

private struct POSStaffSettingsRemoteView: View {
    @Environment(\.posExternalViews) private var externalViews

    let staffMembers: [StaffMemberInfo]
    let manageURL: URL

    @State private var showManageStaff: Bool = false

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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func pinStatusBadge(hasPIN: Bool) -> some View {
        if hasPIN {
            HStack(spacing: POSSpacing.xSmall) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.posSuccess)
                Text(Localization.pinSetLabel)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posSuccess)
            }
        } else {
            HStack(spacing: POSSpacing.xSmall) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.posError)
                Text(Localization.noPINLabel)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posError)
            }
        }
    }

    var manageStaffCard: some View {
        POSInformationCard {
            Button {
                showManageStaff = true
            } label: {
                HStack(spacing: POSSpacing.small) {
                    Image(systemName: "link")
                        .font(.posBodyMediumBold)
                        .foregroundStyle(Color.posPrimary)
                    Text(Localization.manageStaffButton)
                        .font(.posBodyMediumBold)
                        .foregroundStyle(Color.posPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }

    var footerText: some View {
        Text(Localization.remoteFooter)
            .font(.posBodyMediumRegular())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, POSPadding.small)
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

    static let passcodesLabel = NSLocalizedString(
        "posStaffSettingsView.passcodesLabel",
        value: "Passcodes",
        comment: "Toggle label to enable or disable passcodes in POS staff settings."
    )

    static let passcodesDescription = NSLocalizedString(
        "posStaffSettingsView.passcodesDescription",
        value: "When enabled, POS can be locked and staff use PINs to access the register.",
        comment: "Description of the passcodes toggle in POS staff settings."
    )

    static let ownerPasscodeLabel = NSLocalizedString(
        "posStaffSettingsView.ownerPasscodeLabel",
        value: "Owner passcode",
        comment: "Label for the owner passcode row in POS staff settings."
    )

    static let ownerPasscodeDescription = NSLocalizedString(
        "posStaffSettingsView.ownerPasscodeDescription",
        value: "Full access to all POS features and can approve restricted actions",
        comment: "Description of the owner passcode role in POS staff settings."
    )

    static let cashierPasscodeLabel = NSLocalizedString(
        "posStaffSettingsView.cashierPasscodeLabel",
        value: "Cashier passcode",
        comment: "Label for the cashier passcode row in POS staff settings."
    )

    static let cashierPasscodeDescription = NSLocalizedString(
        "posStaffSettingsView.cashierPasscodeDescription",
        value: "Process sales and payments. Refunds and settings require owner approval",
        comment: "Description of the cashier passcode role in POS staff settings."
    )

    static let setButton = NSLocalizedString(
        "posStaffSettingsView.setButton",
        value: "Set",
        comment: "Button title to set a new passcode for a role in POS staff settings."
    )

    static let changeButton = NSLocalizedString(
        "posStaffSettingsView.changeButton",
        value: "Change",
        comment: "Button title to change an existing passcode for a role in POS staff settings."
    )

    static let pinEntrySubtitle = NSLocalizedString(
        "posStaffSettingsView.pinEntrySubtitle",
        value: "Enter a 4-digit PIN",
        comment: "Subtitle shown in the PIN entry modal when setting or changing a PIN."
    )

    static let setOwnerPasscodeTitle = NSLocalizedString(
        "posStaffSettingsView.setOwnerPasscodeTitle",
        value: "Set Owner Passcode",
        comment: "Title for the PIN entry modal when setting the owner passcode."
    )

    static let changeOwnerPasscodeTitle = NSLocalizedString(
        "posStaffSettingsView.changeOwnerPasscodeTitle",
        value: "Change Owner Passcode",
        comment: "Title for the PIN entry modal when changing the owner passcode."
    )

    static let setCashierPasscodeTitle = NSLocalizedString(
        "posStaffSettingsView.setCashierPasscodeTitle",
        value: "Set Cashier Passcode",
        comment: "Title for the PIN entry modal when setting the cashier passcode."
    )

    static let changeCashierPasscodeTitle = NSLocalizedString(
        "posStaffSettingsView.changeCashierPasscodeTitle",
        value: "Change Cashier Passcode",
        comment: "Title for the PIN entry modal when changing the cashier passcode."
    )

    static let invalidPINError = NSLocalizedString(
        "posStaffSettingsView.invalidPINError",
        value: "PIN must be 4-6 digits",
        comment: "Error message shown when an invalid PIN format is entered in POS staff settings."
    )

    static let pinSetConfirmationFormat = NSLocalizedString(
        "posStaffSettingsView.pinSetConfirmationFormat",
        value: "%1$@ passcode has been updated",
        comment: "Confirmation message after successfully setting a passcode. %1$@ is the role name (Owner or Cashier)."
    )

    static let ownerRoleName = NSLocalizedString(
        "posStaffSettingsView.ownerRoleName",
        value: "Owner",
        comment: "Role name used in the passcode confirmation message for the owner role."
    )

    static let cashierRoleName = NSLocalizedString(
        "posStaffSettingsView.cashierRoleName",
        value: "Cashier",
        comment: "Role name used in the passcode confirmation message for the cashier role."
    )

    static let localFooter = NSLocalizedString(
        "posStaffSettingsView.localFooter",
        value: "POS locks when you tap Lock POS from the menu.",
        comment: "Footer text explaining how POS locking works in local mode."
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
        "posStaffSettingsView.manageStaffButton",
        value: "Manage staff in WordPress admin",
        comment: "Button to open the WordPress admin staff management page."
    )

    static let manageStaffWebTitle = NSLocalizedString(
        "posStaffSettingsView.manageStaffWebTitle",
        value: "Manage Staff",
        comment: "Navigation title for the web view showing WordPress admin staff management."
    )

    static let remoteFooter = NSLocalizedString(
        "posStaffSettingsView.remoteFooter",
        value: "POS locks when you tap Lock POS from the menu, or after 30 minutes of inactivity.",
        comment: "Footer text explaining how POS locking works in remote mode."
    )
}

// MARK: - Previews

#if DEBUG
#Preview("Local - Passcodes Off") {
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
