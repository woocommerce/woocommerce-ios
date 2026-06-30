import SwiftUI
import struct WooFoundation.WooAnalyticsEvent
import enum Yosemite.POSStaffPreset

struct POSFloatingControlView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posAccessSession) private var session
    @Environment(\.posAnalytics) private var analytics
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var showSupport: Bool
    @Binding private var showDocumentation: Bool
    /// Invoked when the Exit POS menu item is tapped. The host gates it on `.exitPOS` before
    /// presenting the exit confirmation.
    private let onExitSelected: () -> Void
    /// Invoked when the Settings menu item is tapped. The host gates it on `.viewPOSSettings` before
    /// presenting the settings screen.
    private let onSettingsSelected: () -> Void
    /// Invoked when the Orders menu item is tapped.
    private let onOrdersSelected: () -> Void
    @State private var showProductRestrictionsModal: Bool = false
    @State private var showBarcodeScanningModal: Bool = false

    init(onExitSelected: @escaping () -> Void,
         showSupport: Binding<Bool>,
         showDocumentation: Binding<Bool>,
         onSettingsSelected: @escaping () -> Void,
         onOrdersSelected: @escaping () -> Void) {
        self.onExitSelected = onExitSelected
        self._showSupport = showSupport
        self._showDocumentation = showDocumentation
        self.onSettingsSelected = onSettingsSelected
        self.onOrdersSelected = onOrdersSelected
    }

    var body: some View {
        HStack {
            Menu {
                menuOptions()
            } label: {
                VStack {
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.posBodyLargeBold)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        .foregroundStyle(fontColor)
                    Spacer()
                }
                .frame(width: Constants.size)
            }
            .accessibilityIdentifier("pos-menu-button")
            .background(backgroundColor)
            .cornerRadius(Constants.cornerRadius)
            .disabled(posModel.paymentState.card == .processingPayment)

            CardReaderConnectionStatusView()
                .foregroundStyle(fontColor)
                .background(backgroundColor)
                .cornerRadius(Constants.cornerRadius)
                .disabled(posModel.paymentState.shownFullScreen)
                .disabled(horizontalSizeClass != .regular)
        }
        .posModal(isPresented: $showProductRestrictionsModal) {
            SimpleProductsOnlyInformation(isPresented: $showProductRestrictionsModal)
        }
        .posModal(isPresented: $showBarcodeScanningModal) {
            POSBarcodeScannerSetup(isPresented: $showBarcodeScanningModal, analytics: analytics)
        }
        .frame(height: Constants.size)
        .background(Color.clear)
        .animation(.default, value: backgroundAppearance)
        .posShadow(.large, cornerRadius: Constants.cornerRadius)
    }
}

private extension POSFloatingControlView {
    @ViewBuilder private func menuOptions() -> some View {
        // The menu anchors above the ellipsis button, so the first-declared items render nearest the
        // button (visually at the bottom). Declaring the signed-in operator first places it at the
        // very bottom of the menu, below a divider — an informational, non-actionable row.
        if let staff = session.currentStaff {
            Label {
                Text(operatorMenuLabel(staff))
            } icon: {
                Image(systemName: "person.circle")
            }
            .foregroundStyle(.secondary)
            .disabled(true)
            .accessibilityIdentifier("pos-operator-menu-item")

            Divider()
        }

        Button {
            analytics.track(.pointOfSaleExitMenuItemTapped)
            onExitSelected()
        } label: {
            Label(
                title: { Text(Localization.exitPointOfSale) },
                icon: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
            )
        }
        .accessibilityIdentifier("pos-exit-menu-item")
        if horizontalSizeClass == .regular || isPhoneLayout {
            Button {
                analytics.track(.pointOfSaleSettingsMenuItemTapped)
                onSettingsSelected()
            } label: {
                Label(
                    title: { Text(Localization.settings) },
                    icon: { Image(systemName: "gearshape") }
                )
            }
            .accessibilityIdentifier("pos-settings-menu-item")

            if featureFlags.isFeatureFlagEnabled(.pointOfSaleHistoricalOrdersi1) {
                Button {
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersMenuItemTapped())
                    onOrdersSelected()
                } label: {
                    Label(
                        title: { Text(Localization.orders) },
                        icon: { Image(systemName: "text.document") }
                    )
                }
            }

            if canLockPOS {
                Button {
                    session.lock()
                } label: {
                    Label(
                        title: { Text(Localization.lockPOS) },
                        icon: { Image(systemName: "lock") }
                    )
                }
                .accessibilityIdentifier("pos-lock-menu-item")
            }
        }
    }

    private var isPhoneLayout: Bool {
        horizontalSizeClass == .compact &&
        featureFlags.isFeatureFlagEnabled(.pointOfSalePhonePrototype)
    }

    private var isRolesEnabled: Bool {
        featureFlags.isFeatureFlagEnabled(.pointOfSaleRoles)
    }

    /// Only offer Lock POS when access is actually PIN-gated — i.e. some staff member has a PIN to
    /// unlock with. Without this, locking a session that has no PINs (roles on, but `/staff` returned
    /// nobody PIN-backed) would strand the operator on a lock screen that no PIN can dismiss.
    private var canLockPOS: Bool {
        isRolesEnabled && session.hasAnyPINs
    }

    /// Formats the signed-in operator as "Name - Role" (e.g. "Thomas - Cashier"). When the display
    /// name already matches the role label, only the role is shown to avoid "Cashier - Cashier".
    private func operatorMenuLabel(_ staff: POSStaff) -> String {
        let roleName = roleDisplayName(for: staff.preset)
        guard staff.displayName.caseInsensitiveCompare(roleName) != .orderedSame else {
            return roleName
        }
        return String.localizedStringWithFormat(Localization.operatorLabelFormat, staff.displayName, roleName)
    }

    /// Maps the role preset to a short display label shown beside the operator name in the menu.
    private func roleDisplayName(for preset: POSStaffPreset) -> String {
        switch preset {
        case .admin:
            return Localization.roleAdmin
        case .manager:
            return Localization.roleManager
        case .cashier:
            return Localization.roleCashier
        }
    }
}

private extension POSFloatingControlView {
    var backgroundColor: Color {
        switch backgroundAppearance {
        case .primary:
            .posSurfaceContainerLow
        case .secondary:
            .posDisabledContainer
        }
    }

    var fontColor: Color {
        switch backgroundAppearance {
        case .primary:
            .posOnSurface
        case .secondary:
            Self.secondaryFontColor
        }
    }
}

extension POSFloatingControlView {
    static var secondaryFontColor: Color {
        .posOnDisabledContainer
    }
}

private extension POSFloatingControlView {
    enum Constants {
        static let size: CGFloat = 80
        static let cornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
    }

    enum Localization {
        static let orders = NSLocalizedString(
            "pointOfSale.floatingButtons.orders.button.title",
            value: "Orders",
            comment: "The title of the menu button to access Point of Sale historical orders, shown in a fullscreen view."
        )

        static let lockPOS = NSLocalizedString(
            "pointOfSale.floatingButtons.lock.button.title",
            value: "Lock POS",
            comment: "The title of the menu button to lock Point of Sale, requiring PIN entry to continue."
        )

        static let exitPointOfSale = NSLocalizedString(
            "pointOfSale.floatingButtons.exit.button.title",
            value: "Exit POS",
            comment: "The title of the menu button to exit Point of Sale, shown in a popover menu." +
            "The action is confirmed in a modal."
        )

        static let settings = NSLocalizedString(
            "pointOfSale.floatingButtons.settings.button.title",
            value: "Settings",
            comment: "The title of the menu button to access Point of Sale settings."
        )

        static let operatorLabelFormat = NSLocalizedString(
            "pointOfSale.floatingButtons.operator.labelFormat",
            value: "%1$@ - %2$@",
            comment: "Format for the signed-in POS operator shown in the menu: name, then role, " +
            "e.g. \"Thomas - Cashier\". %1$@ is the staff name, %2$@ is the role."
        )

        static let roleAdmin = NSLocalizedString(
            "pointOfSale.floatingButtons.role.admin",
            value: "Admin",
            comment: "Display name for the admin role shown beside the operator name in the POS menu."
        )

        static let roleManager = NSLocalizedString(
            "pointOfSale.floatingButtons.role.manager",
            value: "Manager",
            comment: "Display name for the manager role shown beside the operator name in the POS menu."
        )

        static let roleCashier = NSLocalizedString(
            "pointOfSale.floatingButtons.role.cashier",
            value: "Cashier",
            comment: "Display name for the cashier role shown beside the operator name in the POS menu."
        )
    }
}

#if DEBUG

#Preview("Reader Disconnected") {
    POSFloatingControlView(onExitSelected: {},
                           showSupport: .constant(false),
                           showDocumentation: .constant(false),
                           onSettingsSelected: {},
                           onOrdersSelected: {})
        .environment(\.posBackgroundAppearance, .primary)
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#Preview("Reader Connected") {
    let paymentService = CardPresentPaymentPreviewService()
    paymentService.readerConnectionStatus = .connected(.init(name: "", batteryLevel: 0.6))
    let posModel = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: paymentService
    )
    return POSFloatingControlView(onExitSelected: {},
                                  showSupport: .constant(false),
                                  showDocumentation: .constant(false),
                                  onSettingsSelected: {},
                                  onOrdersSelected: {})
        .environment(\.posBackgroundAppearance, .primary)
        .environment(posModel)
}

#Preview("Secondary/disabled Background") {
    POSFloatingControlView(onExitSelected: {},
                           showSupport: .constant(false),
                           showDocumentation: .constant(false),
                           onSettingsSelected: {},
                           onOrdersSelected: {})
        .environment(\.posBackgroundAppearance, .secondary)
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#Preview("Signed-in Operator") {
    let session = MockPOSAccessSession(
        currentStaff: POSStaff(userID: 1,
                               displayName: "Thomas",
                               preset: .cashier,
                               capabilities: [])
    )
    return POSFloatingControlView(onExitSelected: {},
                                  showSupport: .constant(false),
                                  showDocumentation: .constant(false),
                                  onSettingsSelected: {},
                                  onOrdersSelected: {})
        .environment(\.posBackgroundAppearance, .primary)
        .environment(\.posAccessSession, session)
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#endif
