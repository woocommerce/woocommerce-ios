import SwiftUI

// MARK: - Mode & Data Types

public enum POSStaffSettingsMode {
    /// Local mode with on-device PINs. The `onAdminPINSet` callback is called with the PIN
    /// when the admin PIN is first configured, allowing the caller to sign in the admin operator.
    case local(pinService: POSPINService, onAdminPINSet: ((String) -> Void)? = nil)
    case remote(loadStaff: () async throws -> [StaffMemberInfo], manageURL: URL)
}

public struct StaffMemberInfo: Identifiable, Sendable {
    public let id: Int64
    public let displayName: String
    public let role: String
    public let hasPIN: Bool

    public init(id: Int64, displayName: String, role: String, hasPIN: Bool) {
        self.id = id
        self.displayName = displayName
        self.role = role
        self.hasPIN = hasPIN
    }
}

// MARK: - View

struct POSStaffSettingsView: View {
    let mode: POSStaffSettingsMode

    var body: some View {
        switch mode {
        case .local(let pinService, let onAdminPINSet):
            POSStaffSettingsLocalView(pinService: pinService, onAdminPINSet: onAdminPINSet)
        case .remote(let loadStaff, let manageURL):
            POSStaffSettingsRemoteView(loadStaff: loadStaff, manageURL: manageURL)
        }
    }
}

// MARK: - Local Mode View

private struct POSStaffSettingsLocalView: View {
    let pinService: POSPINService
    let onAdminPINSet: ((String) -> Void)?
    @Environment(\.posPermissions) private var permissions
    @State private var pinManager: POSStaffPINManager

    @AppStorage("com.woocommerce.pos.pinAccessEnabled") private var pinAccessEnabled: Bool = false

    @State private var showPINEntry: Bool = false
    @State private var pinEntryRole: PINRole = .manager
    @State private var pinEntryState: POSPINEntryState = .idle
    @State private var showGuidedAccessModal: Bool = false

    init(pinService: POSPINService, onAdminPINSet: ((String) -> Void)? = nil) {
        self.pinService = pinService
        self.onAdminPINSet = onAdminPINSet
        self._pinManager = State(initialValue: POSStaffPINManager(pinService: pinService))
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.staffTitle)
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    pinAccessToggleCard

                    if pinAccessEnabled {
                        pinManagementCard
                    }

                    footerText

                    guidedAccessSection
                }
                .padding(.horizontal, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .onAppear {
            pinManager.refresh()
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

                if pinManager.adminPINSet {
                    Divider()
                        .padding(.vertical, POSPadding.small)
                    cashierPINRow
                }
            }
        }
    }

    var ownerPINRow: some View {
        pinRow(
            label: Localization.adminPINLabel,
            description: Localization.adminPINDescription,
            isPINSet: pinManager.adminPINSet,
            role: .manager
        )
    }

    var cashierPINRow: some View {
        pinRow(
            label: Localization.cashierPINLabel,
            description: Localization.cashierPINDescription,
            isPINSet: pinManager.cashierPINSet,
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

                Text(description)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(.secondary)
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

    var guidedAccessSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            Text(Localization.deviceSecurityTitle)
                .font(.posBodyMediumBold)
                .foregroundStyle(Color.posOnSurface)

            HStack(spacing: POSSpacing.small) {
                Text(Localization.guidedAccessDescription)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(.secondary)

                if UIAccessibility.isGuidedAccessEnabled {
                    HStack(spacing: POSSpacing.xSmall) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.posSuccess)
                        Text(Localization.guidedAccessActive)
                            .font(.posBodySmallRegular())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                showGuidedAccessModal = true
            } label: {
                Text(Localization.guidedAccessButton)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .compact))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, POSPadding.small)
        .posModal(isPresented: $showGuidedAccessModal) {
            guidedAccessModalContent
        }
    }

    private var guidedAccessModalContent: some View {
        VStack(spacing: POSSpacing.xLarge) {
            HStack {
                Spacer()
                Button {
                    showGuidedAccessModal = false
                } label: {
                    Text(Image(systemName: "xmark"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurfaceVariantLowest)
            }

            VStack(spacing: POSSpacing.large) {
                Image(systemName: "lock.ipad")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundColor(.posOnSurfaceVariantLowest)

                Text(Localization.guidedAccessModalTitle)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
                    .multilineTextAlignment(.center)

                Text(Localization.guidedAccessModalDescription)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                guidedAccessStep(number: 1, text: Localization.guidedAccessStep1)
                guidedAccessStep(number: 2, text: Localization.guidedAccessStep2)
                guidedAccessStep(number: 3, text: Localization.guidedAccessStep3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showGuidedAccessModal = false
                if let url = URL(string: "App-prefs:ACCESSIBILITY") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text(Localization.guidedAccessContinue)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
        .padding(POSPadding.xLarge)
        .frame(maxWidth: 500)
        .background(Color.posSurfaceBright)
        .cornerRadius(POSCornerRadiusStyle.large.value)
    }

    private func guidedAccessStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: POSSpacing.medium) {
            Text("\(number)")
                .font(.posBodyMediumBold)
                .foregroundColor(.posSurfaceBright)
                .frame(width: 28, height: 28)
                .background(Color.posPrimary)
                .clipShape(Circle())
            Text(text)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurface)
        }
    }


    var pinEntryModal: some View {
        VStack(spacing: POSSpacing.xLarge) {
            HStack {
                Spacer()
                Button {
                    dismissPINEntry()
                } label: {
                    Text(Image(systemName: "xmark"))
                        .font(.posButtonSymbolLarge)
                }
                .foregroundColor(.posOnSurfaceVariantLowest)
                .accessibilityLabel(Localization.closeAccessibilityLabel)
            }

            POSPINEntryView(
                title: pinEntryTitle,
                subtitle: Localization.pinEntrySubtitle,
                state: $pinEntryState,
                onPINEntered: { pin in
                    handlePINEntered(pin)
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
            return pinManager.adminPINSet ? Localization.changeAdminPINTitle : Localization.setAdminPINTitle
        case .cashier:
            return pinManager.cashierPINSet ? Localization.changeCashierPINTitle : Localization.setCashierPINTitle
        }
    }

    func handlePINAccessToggleChanged(_ enabled: Bool) {
        if enabled {
            presentPINEntry(for: .manager)
        } else {
            pinManager.clearAllPINs()
        }
    }

    func presentPINEntry(for role: PINRole) {
        pinEntryRole = role
        pinEntryState = .idle
        showPINEntry = true
    }

    func dismissPINEntry() {
        showPINEntry = false
        if !pinManager.adminPINSet && pinAccessEnabled {
            pinAccessEnabled = false
        }
    }

    func handlePINEntered(_ pin: String) {
        let success = pinManager.setPIN(pin, for: pinEntryRole)
        if !success {
            pinEntryState = .error(message: Localization.invalidPINError)
            return
        }
        // When admin PIN is first set, sign in as admin so the lock screen doesn't appear
        if pinEntryRole == .manager, permissions.currentOperator == nil {
            onAdminPINSet?(pin)
        }
        dismissPINEntry()
    }
}

// MARK: - Remote Mode View

private struct POSStaffSettingsRemoteView: View {
    @Environment(\.posExternalViews) private var externalViews
    @Environment(\.posPermissions) private var permissions

    let loadStaff: () async throws -> [StaffMemberInfo]
    let manageURL: URL

    @State private var staffMembers: [StaffMemberInfo] = []
    @State private var isLoading: Bool = false
    @State private var loadError: Error?
    @State private var showManageStaff: Bool = false

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.staffTitle)
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, POSPadding.xLarge)
                    } else if let loadError {
                        staffLoadErrorView(error: loadError)
                    } else if staffMembers.isEmpty == false {
                        staffListCard
                    }
                    manageStaffCard
                    footerText
                }
                .padding(.horizontal, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .task {
            await fetchStaff()
        }
        .posFullScreenCover(isPresented: $showManageStaff) {
            externalViews.createAuthenticatedWebView(
                url: manageURL,
                title: Localization.manageStaffWebTitle,
                completion: {
                    showManageStaff = false
                    Task {
                        await fetchStaff()
                    }
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
                ForEach(Array(sortedStaffMembers.enumerated()), id: \.element.id) { index, member in
                    staffRow(member: member, isCurrentOperator: member.id == currentOperatorID)

                    if index < sortedStaffMembers.count - 1 {
                        Divider()
                            .padding(.vertical, POSPadding.small)
                    }
                }
            }
        }
    }

    private var currentOperatorID: Int64? {
        permissions.currentOperator?.userID
    }

    private var sortedStaffMembers: [StaffMemberInfo] {
        staffMembers.sorted { lhs, rhs in
            let lhsCurrent = lhs.id == currentOperatorID
            let rhsCurrent = rhs.id == currentOperatorID
            if lhsCurrent != rhsCurrent {
                return lhsCurrent
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    func staffRow(member: StaffMemberInfo, isCurrentOperator: Bool) -> some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                Text(member.displayName)
                    .font(.posBodyMediumBold)
                    .foregroundStyle(Color.posOnSurface)
                Text(Self.displayName(for: member.role))
                    .font(.posBodySmallRegular())
                    .foregroundStyle(.secondary)
                if isCurrentOperator {
                    signedInBadge
                }
            }

            Spacer()

            pinStatusBadge(hasPIN: member.hasPIN)
        }
        .padding(.vertical, POSPadding.xSmall)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func displayName(for role: String) -> String {
        switch role {
        case "administrator":
            return Localization.roleAdmin
        case "shop_manager":
            return Localization.roleShopManager
        case "pos_manager":
            return Localization.rolePOSManager
        case "pos_cashier":
            return Localization.rolePOSCashier
        default:
            return role
        }
    }

    private var signedInBadge: some View {
        Text(Localization.signedInBadge)
            .font(.posCaptionRegular)
            .foregroundStyle(Color.posOnInfoLowest)
            .padding(.horizontal, POSPadding.small)
            .padding(.vertical, POSPadding.xSmall)
            .background(Color.posInfoLowest)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
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
            showManageStaff = true
        } label: {
            Text(Localization.manageStaffButton)
        }
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        .frame(maxWidth: .infinity)
    }

    func staffLoadErrorView(error: Error) -> some View {
        VStack(spacing: POSSpacing.medium) {
            Text(Localization.staffLoadError)
                .font(.posBodyMediumRegular())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await fetchStaff() }
            } label: {
                Text(Localization.staffLoadRetry)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .compact))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, POSPadding.xLarge)
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
    func fetchStaff() async {
        isLoading = true
        loadError = nil
        do {
            staffMembers = try await loadStaff()
        } catch {
            loadError = error
        }
        isLoading = false
    }

}

// MARK: - Constants

private enum Constants {
    static let pinEntryModalMaxWidth: CGFloat = 500
}

// MARK: - Localization

private enum Localization {
    // MARK: Common
    static let staffTitle = NSLocalizedString(
        "posStaffSettingsView.staffTitle",
        value: "Staff",
        comment: "Navigation title for the staff settings detail view in POS settings."
    )

    static let closeAccessibilityLabel = NSLocalizedString(
        "posStaffSettingsView.close.accessibilityLabel",
        value: "Close",
        comment: "Accessibility label for the close button on the POS staff settings PIN entry modal"
    )

    // MARK: Local Mode
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

    static let adminPINLabel = NSLocalizedString(
        "posStaffSettingsView.adminPINLabel",
        value: "Admin PIN",
        comment: "Label for the admin PIN row in POS staff settings."
    )

    static let adminPINDescription = NSLocalizedString(
        "posStaffSettingsView.adminPINDescription",
        value: "Full access to all POS features and can approve restricted actions.",
        comment: "Description of the admin PIN role in POS staff settings."
    )

    static let cashierPINLabel = NSLocalizedString(
        "posStaffSettingsView.cashierPINLabel",
        value: "Cashier PIN",
        comment: "Label for the cashier PIN row in POS staff settings."
    )

    static let cashierPINDescription = NSLocalizedString(
        "posStaffSettingsView.cashierPINDescription.v2",
        value: "Process sales and payments. Restricted actions like refunds, coupon creation, and settings require admin approval.",
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

    static let setAdminPINTitle = NSLocalizedString(
        "posStaffSettingsView.setAdminPINTitle",
        value: "Set Admin PIN",
        comment: "Title for the PIN entry modal when setting the admin PIN."
    )

    static let changeAdminPINTitle = NSLocalizedString(
        "posStaffSettingsView.changeAdminPINTitle",
        value: "Change Admin PIN",
        comment: "Title for the PIN entry modal when changing the admin PIN."
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


    static let localFooter = NSLocalizedString(
        "posStaffSettingsView.localAutoLockFooter",
        value: "POS locks when you tap Lock POS from the menu, or automatically after 5 minutes of inactivity.",
        comment: "Footer text explaining how POS locking works in local mode, including auto-lock timeout."
    )

    static let deviceSecurityTitle = NSLocalizedString(
        "posStaffSettingsView.deviceSecurityTitle",
        value: "Device security",
        comment: "Title for the device security section in POS staff settings."
    )

    static let guidedAccessDescription = NSLocalizedString(
        "posStaffSettingsView.guidedAccessDescription",
        value: "For additional security, enable Guided Access to prevent staff from leaving the app.",
        comment: "Description of the Guided Access feature in POS staff settings."
    )

    static let guidedAccessButton = NSLocalizedString(
        "posStaffSettingsView.guidedAccessButton",
        value: "Set up Guided Access",
        comment: "Button to open iOS Settings to set up Guided Access in POS staff settings."
    )

    static let guidedAccessModalTitle = NSLocalizedString(
        "posStaffSettingsView.guidedAccessModalTitle",
        value: "Set up Guided Access",
        comment: "Title of the Guided Access setup modal in POS staff settings."
    )

    static let guidedAccessModalDescription = NSLocalizedString(
        "posStaffSettingsView.guidedAccessModalDescription",
        value: "Guided Access locks the iPad to this app, preventing staff from switching apps or exiting. A passcode is required to turn it off.",
        comment: "Description explaining Guided Access in the setup modal."
    )

    static let guidedAccessStep1 = NSLocalizedString(
        "posStaffSettingsView.guidedAccessStep1",
        value: "Turn on Guided Access",
        comment: "Step 1 instruction in the Guided Access setup modal."
    )

    static let guidedAccessStep2 = NSLocalizedString(
        "posStaffSettingsView.guidedAccessStep2",
        value: "Set a passcode for Guided Access",
        comment: "Step 2 instruction in the Guided Access setup modal."
    )

    static let guidedAccessStep3 = NSLocalizedString(
        "posStaffSettingsView.guidedAccessStep3",
        value: "Enable the Accessibility Shortcut (triple-click home or side button to start)",
        comment: "Step 3 instruction in the Guided Access setup modal."
    )

    static let guidedAccessContinue = NSLocalizedString(
        "posStaffSettingsView.guidedAccessContinue",
        value: "Open Settings",
        comment: "Button in the Guided Access setup modal that opens iOS Settings."
    )

    static let guidedAccessActive = NSLocalizedString(
        "posStaffSettingsView.guidedAccessActive",
        value: "Active",
        comment: "Status label shown when Guided Access is currently enabled on the device."
    )

    // MARK: Remote Mode
    static let signedInBadge = NSLocalizedString(
        "posStaffSettingsView.signedInBadge",
        value: "Signed in",
        comment: "Badge label shown next to the currently signed-in staff member in the POS staff list."
    )

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

    static let roleAdmin = NSLocalizedString(
        "posStaffSettingsView.role.admin",
        value: "Admin",
        comment: "Display name for the administrator role in the POS staff list."
    )

    static let roleShopManager = NSLocalizedString(
        "posStaffSettingsView.role.shopManager",
        value: "Shop Manager",
        comment: "Display name for the shop manager role in the POS staff list."
    )

    static let rolePOSManager = NSLocalizedString(
        "posStaffSettingsView.role.posManager",
        value: "POS Manager",
        comment: "Display name for the POS manager role in the POS staff list."
    )

    static let rolePOSCashier = NSLocalizedString(
        "posStaffSettingsView.role.posCashier",
        value: "POS Cashier",
        comment: "Display name for the POS cashier role in the POS staff list."
    )

    static let staffLoadError = NSLocalizedString(
        "posStaffSettingsView.staffLoadError",
        value: "Unable to load staff. Check your connection and try again.",
        comment: "Error message shown when the remote staff list fails to load."
    )

    static let staffLoadRetry = NSLocalizedString(
        "posStaffSettingsView.staffLoadRetry",
        value: "Retry",
        comment: "Button to retry loading the remote staff list after a failure."
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
            loadStaff: { members },
            manageURL: URL(string: "https://example.com/wp-admin/admin.php?page=wc-settings&tab=point-of-sale&section=staff")!
        )
    )
}
#endif
