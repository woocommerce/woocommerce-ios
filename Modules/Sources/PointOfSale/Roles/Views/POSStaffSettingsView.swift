import SwiftUI
import struct Yosemite.POSStaffMember
import enum Yosemite.POSStaffPreset

struct POSStaffSettingsView: View {
    @Environment(\.posExternalViews) private var externalViews
    @Environment(\.posAccessSession) private var session

    let service: POSStaffSettingsService
    /// Gates opening the staff-management web view on `managePOSStaff`. Defaults to running it directly
    /// (previews / no host gate).
    private let requestManageStaffPermission: POSPermissionRequest

    @State private var state: LoadState = .idle
    @State private var showsManageStaff: Bool = false

    init(service: POSStaffSettingsService,
         requestManageStaffPermission: @escaping POSPermissionRequest = { $0() }) {
        self.service = service
        self.requestManageStaffPermission = requestManageStaffPermission
    }

    private enum LoadState {
        case idle
        case loading
        case loaded([POSStaffMember])
        case failed(Error)
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.staffTitle)
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    switch state {
                    case .idle, .loading:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, POSPadding.xLarge)
                    case .failed(let error):
                        staffLoadErrorView(error: error)
                    case .loaded(let staff):
                        if !staff.isEmpty {
                            staffListCard(staff: staff)
                        }
                    }
                    if manageStaffURL != nil {
                        manageStaffCard
                    }
                    footerText
                }
                .padding(.horizontal, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .task {
            await loadStaffIfNeeded()
        }
        .posFullScreenCover(isPresented: $showsManageStaff) {
            if let manageStaffURL {
                externalViews.createAuthenticatedWebView(
                    url: manageStaffURL,
                    title: Localization.manageStaffWebTitle,
                    completion: {
                        showsManageStaff = false
                        // Silent refresh: the list is already on screen, so update it in place
                        // without the spinner (which could otherwise stick after the cover dismiss).
                        Task { await fetchStaff(showsLoading: false) }
                    }
                )
            }
        }
    }
}

// MARK: - Subviews

private extension POSStaffSettingsView {
    func staffListCard(staff: [POSStaffMember]) -> some View {
        let sortedStaff = sortedStaffMembers(staff)
        return POSInformationCard {
            VStack(spacing: POSSpacing.none) {
                ForEach(Array(sortedStaff.enumerated()), id: \.element.userID) { index, member in
                    staffRow(member: member, isCurrentOperator: member.userID == currentOperatorID)

                    if index < sortedStaff.count - 1 {
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

    func sortedStaffMembers(_ staff: [POSStaffMember]) -> [POSStaffMember] {
        staff.sorted { lhs, rhs in
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

    /// Maps the role preset to a display label.
    static func displayName(for preset: POSStaffPreset) -> String {
        switch preset {
        case .admin:
            return Localization.roleAdmin
        case .manager:
            return Localization.rolePOSManager
        case .cashier:
            return Localization.rolePOSCashier
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

    /// The wp-admin staff-management URL, or `nil` when the host didn't supply a usable one. When
    /// `nil` the manage-on-web button is hidden rather than opening an empty web view.
    var manageStaffURL: URL? {
        URL(string: service.manageStaffURL)
    }

    var manageStaffCard: some View {
        Button {
            // Always offered; gated on `managePOSStaff` so a staff member without it needs an
            // authorized override before the wp-admin staff page opens (it's also gated server-side
            // on `manage_woocommerce`). The web view authenticates as the device account, so the
            // override authorizes opening it rather than acting as the approver.
            requestManageStaffPermission { showsManageStaff = true }
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
    /// Loads once on first appearance. Presenting the full-screen Manage staff web view makes this
    /// view disappear, so `.task` re-fires on dismiss; the `.idle` guard keeps that from re-running
    /// the initial load. Post-web changes are picked up by the silent refresh in the web view's
    /// completion handler.
    func loadStaffIfNeeded() async {
        guard case .idle = state else { return }
        await fetchStaff()
    }

    /// Loads the staff list. `showsLoading` drives the spinner + error state for the initial load and
    /// retries; pass `false` for a silent in-place refresh (e.g. after returning from the Manage
    /// staff web view), which keeps the current list visible and never strands the spinner.
    func fetchStaff(showsLoading: Bool = true) async {
        if showsLoading {
            state = .loading
        }
        do {
            let staff = try await service.loadStaff()
            // Keep the access session in sync so menu items like "Lock POS" pick up PIN changes made
            // via the Manage staff web view — using the list we just fetched, so the staff endpoint
            // isn't hit a second time.
            await session.refreshPINStatus(using: staff)
            state = .loaded(staff)
        } catch {
            // Silent-refresh failures keep the current list on screen; only the initial load and
            // retry surface the error state.
            if showsLoading {
                state = .failed(error)
            }
        }
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
                           preset: .manager,
                           capabilities: [:],
                           pin: .init(algorithm: "pbkdf2-sha256", iterations: 1,
                                      salt: "c2FsdA==", hash: "aGFzaA==")),
            POSStaffMember(userID: 2,
                           displayName: "Sam Lee",
                           preset: .cashier,
                           capabilities: [:],
                           pin: nil)
        ]
    }

    var manageStaffURL: String { "about:blank" }
}

#Preview {
    POSStaffSettingsView(service: PreviewPOSStaffSettingsService())
}
#endif
