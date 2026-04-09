import SwiftUI

struct POSStaffSettingsView: View {
    let pinService: POSPINService

    @State private var showPINEntry: Bool = false
    @State private var pinEntryRole: PINRole = .manager
    @State private var pinEntryState: POSPINEntryState = .idle
    @State private var confirmationMessage: String?

    @State private var managerPINSet: Bool = false
    @State private var cashierPINSet: Bool = false

    init(pinService: POSPINService) {
        self.pinService = pinService
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.staffTitle)
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    staffPINsCard

                    if let confirmationMessage {
                        confirmationBanner(message: confirmationMessage)
                    }
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

// MARK: - Subviews

private extension POSStaffSettingsView {
    var staffPINsCard: some View {
        POSInformationCard {
            VStack(spacing: POSSpacing.small) {
                pinRow(
                    label: Localization.managerPINLabel,
                    description: Localization.managerPINDescription,
                    isPINSet: managerPINSet,
                    role: .manager
                )

                Divider()
                    .padding(.vertical, POSPadding.small)

                pinRow(
                    label: Localization.cashierPINLabel,
                    description: Localization.cashierPINDescription,
                    isPINSet: cashierPINSet,
                    role: .cashier,
                    showSeparator: false
                )
            }
        }
    }

    @ViewBuilder
    func pinRow(label: String,
                description: String,
                isPINSet: Bool,
                role: PINRole,
                showSeparator: Bool = true) -> some View {
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

            Button(isPINSet ? Localization.changePINButton : Localization.setPINButton) {
                presentPINEntry(for: role)
            }
            .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: .default))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Logic

private extension POSStaffSettingsView {
    var pinEntryTitle: String {
        switch pinEntryRole {
        case .manager:
            return managerPINSet ? Localization.changeManagerPINTitle : Localization.setManagerPINTitle
        case .cashier:
            return cashierPINSet ? Localization.changeCashierPINTitle : Localization.setCashierPINTitle
        }
    }

    func presentPINEntry(for role: PINRole) {
        pinEntryRole = role
        pinEntryState = .idle
        showPINEntry = true
    }

    func dismissPINEntry() {
        showPINEntry = false
    }

    func handlePINEntered(_ pin: String) {
        guard pinService.isValidFormat(pin) else {
            pinEntryState = .error(message: Localization.invalidPINError)
            return
        }

        pinService.setPIN(pin, for: pinEntryRole)
        dismissPINEntry()
        refreshPINStatus()

        let roleName = pinEntryRole == .manager ? Localization.managerRoleName : Localization.cashierRoleName
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
        managerPINSet = pinService.hasPIN(for: .manager)
        cashierPINSet = pinService.hasPIN(for: .cashier)
    }
}

// MARK: - Constants

private extension POSStaffSettingsView {
    enum Constants {
        static let pinEntryModalMaxWidth: CGFloat = 500
        static let confirmationDismissDelay: TimeInterval = 3.0
    }
}

// MARK: - Localization

private extension POSStaffSettingsView {
    enum Localization {
        static let staffTitle = NSLocalizedString(
            "posStaffSettingsView.staffTitle",
            value: "Staff",
            comment: "Navigation title for the staff settings detail view in POS settings."
        )

        static let managerPINLabel = NSLocalizedString(
            "posStaffSettingsView.managerPINLabel",
            value: "Manager PIN",
            comment: "Label for the manager PIN row in POS staff settings."
        )

        static let cashierPINLabel = NSLocalizedString(
            "posStaffSettingsView.cashierPINLabel",
            value: "Cashier PIN",
            comment: "Label for the cashier PIN row in POS staff settings."
        )

        static let managerPINDescription = NSLocalizedString(
            "posStaffSettingsView.managerPINDescription",
            value: "Used to access all POS features and approve restricted actions",
            comment: "Description of the manager PIN role in POS staff settings."
        )

        static let cashierPINDescription = NSLocalizedString(
            "posStaffSettingsView.cashierPINDescription",
            value: "Used for basic sales and payments. Restricted actions require manager approval",
            comment: "Description of the cashier PIN role in POS staff settings."
        )

        static let setPINButton = NSLocalizedString(
            "posStaffSettingsView.setPINButton",
            value: "Set PIN",
            comment: "Button title to set a new PIN for a role in POS staff settings."
        )

        static let changePINButton = NSLocalizedString(
            "posStaffSettingsView.changePINButton",
            value: "Change",
            comment: "Button title to change an existing PIN for a role in POS staff settings."
        )

        static let pinEntrySubtitle = NSLocalizedString(
            "posStaffSettingsView.pinEntrySubtitle",
            value: "Enter a 4-digit PIN",
            comment: "Subtitle shown in the PIN entry modal when setting or changing a PIN."
        )

        static let setManagerPINTitle = NSLocalizedString(
            "posStaffSettingsView.setManagerPINTitle",
            value: "Set Manager PIN",
            comment: "Title for the PIN entry modal when setting the manager PIN."
        )

        static let changeManagerPINTitle = NSLocalizedString(
            "posStaffSettingsView.changeManagerPINTitle",
            value: "Change Manager PIN",
            comment: "Title for the PIN entry modal when changing the manager PIN."
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
            "posStaffSettingsView.pinSetConfirmationFormat",
            value: "%1$@ PIN has been updated",
            comment: "Confirmation message after successfully setting or changing a PIN. %1$@ is the role name (Manager or Cashier)."
        )

        static let managerRoleName = NSLocalizedString(
            "posStaffSettingsView.managerRoleName",
            value: "Manager",
            comment: "Role name used in the PIN confirmation message for the manager role."
        )

        static let cashierRoleName = NSLocalizedString(
            "posStaffSettingsView.cashierRoleName",
            value: "Cashier",
            comment: "Role name used in the PIN confirmation message for the cashier role."
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Staff Settings - No PINs Set") {
    POSStaffSettingsView(pinService: POSPINService(storage: InMemoryPINStorage()))
}

#Preview("Staff Settings - PINs Set") {
    let storage = InMemoryPINStorage()
    let service = POSPINService(storage: storage)
    service.setPIN("1234", for: .manager)
    service.setPIN("5678", for: .cashier)
    return POSStaffSettingsView(pinService: service)
}
#endif
