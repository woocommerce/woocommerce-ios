import SwiftUI
import struct Networking.POSStaffMember

struct POSStaffSettingsView: View {
    @Environment(\.posExternalViews) private var externalViews
    @Environment(\.posAccessSession) private var session

    let service: POSStaffSettingsService

    @State private var staffMembers: [POSStaffMember] = []
    @State private var isLoading: Bool = false
    @State private var loadError: Error?
    @State private var hasLoadedOnce = false
    @State private var showsManageStaff: Bool = false

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
                    } else if !staffMembers.isEmpty {
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
            // Load once. Presenting the full-screen Manage staff web view makes this view
            // disappear, so `.task` re-fires on dismiss — without this guard that would re-show
            // (and could strand) the spinner. Post-web changes are picked up by the silent refresh
            // in the web view's completion below.
            guard !hasLoadedOnce else { return }
            hasLoadedOnce = true
            await fetchStaff()
        }
        .posFullScreenCover(isPresented: $showsManageStaff) {
            if let manageStaffURL = URL(string: service.manageStaffURL) {
                externalViews.createAuthenticatedWebView(
                    url: manageStaffURL,
                    title: Localization.manageStaffWebTitle,
                    completion: {
                        showsManageStaff = false
                        // Silent refresh: the list is already on screen, so update it in place
                        // without the spinner (which could otherwise stick after the cover dismiss).
                        Task { await fetchStaff(showLoading: false) }
                    }
                )
            }
        }
    }
}

// MARK: - Subviews

private extension POSStaffSettingsView {
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
            showsManageStaff = true
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
}

// MARK: - Logic

private extension POSStaffSettingsView {
    /// Loads the staff list. `showLoading` drives the full-screen spinner + error state for the
    /// initial load and retries; pass `false` for a silent in-place refresh (e.g. after returning
    /// from the Manage staff web view), which keeps the current list visible and never strands the
    /// spinner.
    func fetchStaff(showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
            loadError = nil
        }
        do {
            staffMembers = try await service.loadStaff()
            // Keep the access session in sync so menu items like "Lock POS" pick up
            // PIN changes made via the Manage staff web view without requiring a relaunch.
            await session.refreshPINStatus()
            // Clear any stale error so a successful silent refresh recovers the list.
            loadError = nil
        } catch {
            if showLoading {
                loadError = error
            }
        }
        isLoading = false
    }
}

// MARK: - Localization

private enum Localization {
    static let staffTitle = NSLocalizedString(
        "posStaffSettingsView.staffTitle",
        value: "Staff",
        comment: "Navigation title for the staff settings detail view in POS settings."
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
}

// MARK: - Preview

#if DEBUG
private struct PreviewPOSStaffSettingsService: POSStaffSettingsService {
    func loadStaff() async throws -> [POSStaffMember] {
        [
            POSStaffMember(userID: 1,
                           displayName: "Maya Patel",
                           preset: "pos_manager",
                           capabilities: [:],
                           pin: .init(algorithm: "pbkdf2-sha256", iterations: 1,
                                      salt: "c2FsdA==", hash: "aGFzaA==")),
            POSStaffMember(userID: 2,
                           displayName: "Sam Lee",
                           preset: "pos_cashier",
                           capabilities: [:],
                           pin: nil)
        ]
    }

    var manageStaffURL: String { "about:blank" }
}

#Preview {
//    POSStaffSettingsView(service: PreviewPOSStaffSettingsService())
    Text("Preview unavailable in this environment")

}
#endif
