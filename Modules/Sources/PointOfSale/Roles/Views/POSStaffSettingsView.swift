import SwiftUI
import struct Networking.POSStaffMember

// MARK: - Mode

/// In M1 the staff settings view is read-only with a deep link to wp-admin.
/// `loadStaff` returns the latest server snapshot (already PBKDF2-hashed by `GET /wc-pos/v1/staff`);
/// `manageURL` opens an authenticated web view to wp-admin → Settings → Point of sale → Staff.
public struct POSStaffSettingsMode {
    public let loadStaff: () async throws -> [POSStaffMember]
    public let manageURL: URL

    public init(loadStaff: @escaping () async throws -> [POSStaffMember],
                manageURL: URL) {
        self.loadStaff = loadStaff
        self.manageURL = manageURL
    }
}

// MARK: - View

struct POSStaffSettingsView: View {
    @Environment(\.posExternalViews) private var externalViews
    @Environment(\.posAccessSession) private var session

    let mode: POSStaffSettingsMode

    @State private var staffMembers: [POSStaffMember] = []
    @State private var isLoading: Bool = false
    @State private var loadError: Error?
    @State private var showManageStaff: Bool = false
    @State private var showPINAccessInfo: Bool = false

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
                    } else {
                        pinAccessStatusCard
                        if !staffMembers.isEmpty {
                            staffListCard
                        }
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
                url: mode.manageURL,
                title: Localization.manageStaffWebTitle,
                completion: {
                    showManageStaff = false
                    Task { await fetchStaff() }
                }
            )
        }
        .posModal(isPresented: $showPINAccessInfo) {
            pinAccessInfoModal
        }
    }
}

// MARK: - Subviews

private extension POSStaffSettingsView {
    var anyStaffHasPIN: Bool {
        staffMembers.contains { $0.pin != nil }
    }

    var pinAccessBinding: Binding<Bool> {
        Binding(
            get: { anyStaffHasPIN },
            set: { _ in showPINAccessInfo = true }
        )
    }

    var pinAccessStatusCard: some View {
        POSInformationCard {
            POSInformationCardFieldRowWithToggle(
                label: Localization.pinAccessLabel,
                value: Localization.pinAccessDescription,
                showSeparator: false,
                isOn: pinAccessBinding
            )
        }
    }

    var staffListCard: some View {
        POSInformationCard {
            VStack(spacing: POSSpacing.none) {
                ForEach(Array(sortedStaffMembers.enumerated()), id: \.element.userID) { index, member in
                    staffRow(member: member, isCurrentOperator: member.userID == currentOperatorID)

                    if index < sortedStaffMembers.count - 1 {
                        Divider()
                            .padding(.vertical, POSPadding.small)
                    }
                }
            }
        }
    }

    var currentOperatorID: Int64? {
        session.currentStaff?.userID
    }

    var sortedStaffMembers: [POSStaffMember] {
        staffMembers.sorted { lhs, rhs in
            let lhsCurrent = lhs.userID == currentOperatorID
            let rhsCurrent = rhs.userID == currentOperatorID
            if lhsCurrent != rhsCurrent {
                return lhsCurrent
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    func staffRow(member: POSStaffMember, isCurrentOperator: Bool) -> some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                Text(member.displayName)
                    .font(.posBodyMediumBold)
                    .foregroundStyle(Color.posOnSurface)
                Text(Self.displayName(for: member.preset))
                    .font(.posBodySmallRegular())
                    .foregroundStyle(.secondary)
                if isCurrentOperator {
                    signedInBadge
                }
            }

            Spacer()

            pinStatusBadge(hasPIN: member.pin != nil)
        }
        .padding(.vertical, POSPadding.xSmall)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Maps the server preset slug (`pos_admin` / `pos_manager` / `pos_cashier`, with the older
    /// `administrator` / `shop_manager` kept for resilience) to a display label.
    static func displayName(for preset: String) -> String {
        switch preset {
        case "pos_admin", "administrator":
            return Localization.roleAdmin
        case "shop_manager":
            return Localization.roleShopManager
        case "pos_manager":
            return Localization.rolePOSManager
        case "pos_cashier":
            return Localization.rolePOSCashier
        default:
            return preset
        }
    }

    var signedInBadge: some View {
        Text(Localization.signedInBadge)
            .font(.posCaptionRegular)
            .foregroundStyle(Color.posOnInfoLowest)
            .padding(.horizontal, POSPadding.small)
            .padding(.vertical, POSPadding.xSmall)
            .background(Color.posInfoLowest)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
    }

    /// Neutral indicator using shape (filled vs slashed) rather than colour so it reads
    /// correctly for colourblind users and doesn't imply "No PIN" is an error — staff
    /// PIN setup is managed on the web, so a missing one is informational, not a warning.
    func pinStatusBadge(hasPIN: Bool) -> some View {
        HStack(spacing: POSSpacing.small) {
            Image(systemName: hasPIN ? "lock.fill" : "lock.slash")
                .foregroundStyle(hasPIN ? Color.posOnSurface : Color.posOnSurfaceVariantLowest)
            Text(hasPIN ? Localization.pinSetLabel : Localization.noPINLabel)
                .font(.posBodySmallRegular())
                .foregroundStyle(.secondary)
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
        Text(Localization.footer)
            .font(.posBodyMediumRegular())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, POSPadding.small)
    }

    var pinAccessInfoModal: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            PointOfSaleModalHeader(
                isPresented: $showPINAccessInfo,
                title: .constant(AttributedString(Localization.pinAccessModalTitle))
            )

            Text(anyStaffHasPIN ? Localization.pinAccessModalDisableMessage : Localization.pinAccessModalEnableMessage)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurface)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showPINAccessInfo = false
                showManageStaff = true
            } label: {
                Text(Localization.pinAccessModalManageButton)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
        .padding(POSPadding.xxLarge)
        .background(Color.posSurfaceBright)
        .frame(maxWidth: Constants.modalMaxWidth)
        .padding(.horizontal, POSPadding.medium)
    }
}

// MARK: - Logic

private extension POSStaffSettingsView {
    func fetchStaff() async {
        isLoading = true
        loadError = nil
        do {
            staffMembers = try await mode.loadStaff()
            // Keep the access session in sync so menu items like "Lock POS" pick up
            // PIN changes made via the Manage staff web view without requiring a relaunch.
            await session.refreshPINStatus()
        } catch {
            loadError = error
        }
        isLoading = false
    }
}

// MARK: - Constants

private enum Constants {
    static let modalMaxWidth: CGFloat = 640
}

// MARK: - Localization

private enum Localization {
    static let staffTitle = NSLocalizedString(
        "posStaffSettingsView.staffTitle",
        value: "Staff",
        comment: "Navigation title for the staff settings detail view in POS settings."
    )

    static let pinAccessLabel = NSLocalizedString(
        "posStaffSettingsView.pinAccessLabel",
        value: "PIN access",
        comment: "Toggle label showing whether PIN access is enabled in POS staff settings."
    )

    static let pinAccessDescription = NSLocalizedString(
        "posStaffSettingsView.pinAccessDescription.v2",
        value: "When enabled, POS can be locked and staff use PINs to access it.",
        comment: "Description of the PIN access toggle in POS staff settings."
    )

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
        comment: "Error message shown when the staff list fails to load from the server."
    )

    static let staffLoadRetry = NSLocalizedString(
        "posStaffSettingsView.staffLoadRetry",
        value: "Retry",
        comment: "Button to retry loading the staff list after a failure."
    )

    static let footer = NSLocalizedString(
        "posStaffSettingsView.autoLockFooter",
        value: "POS locks when you tap Lock POS from the menu, or automatically after 5 minutes of inactivity.",
        comment: "Footer text explaining how POS locking works, including auto-lock timeout."
    )

    static let pinAccessModalTitle = NSLocalizedString(
        "pos.pinAccessModal.title.v2",
        value: "Managed on the web",
        comment: "Title of the modal explaining that POS PIN access is controlled via the web admin."
    )

    static let pinAccessModalEnableMessage = NSLocalizedString(
        "pos.pinAccessModal.message.enable",
        value: "PIN access turns on automatically as soon as any staff member has a PIN. Set a PIN for a staff member to turn it on.",
        comment: "Message shown when the operator tries to turn on PIN access from the POS app."
    )

    static let pinAccessModalDisableMessage = NSLocalizedString(
        "pos.pinAccessModal.message.disable",
        value: "To turn PIN access off, remove the PIN from every staff member.",
        comment: "Message shown when the operator tries to turn off PIN access from the POS app."
    )

    static let pinAccessModalManageButton = NSLocalizedString(
        "pos.pinAccessModal.manageButton",
        value: "Manage staff on the web",
        comment: "Primary button in the PIN access info modal that opens the Manage staff web view."
    )
}
