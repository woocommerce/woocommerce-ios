import SwiftUI
import struct WooFoundation.WooAnalyticsEvent

struct POSFloatingControlView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posAccessSession) private var accessSession
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var showExitPOSModal: Bool
    @Binding private var showSupport: Bool
    @Binding private var showDocumentation: Bool
    @Binding private var showSettings: Bool
    private let onOrdersSelected: () -> Void
    @State private var showProductRestrictionsModal: Bool = false
    @State private var showBarcodeScanningModal: Bool = false
    @State private var showOrders: Bool = false
    @State private var exitOverrideHandler = POSManagerOverrideHandler()
    @State private var settingsOverrideHandler = POSManagerOverrideHandler()

    init(showExitPOSModal: Binding<Bool>,
         showSupport: Binding<Bool>,
         showDocumentation: Binding<Bool>,
         showSettings: Binding<Bool>,
         onOrdersSelected: @escaping () -> Void) {
        self._showExitPOSModal = showExitPOSModal
        self._showSupport = showSupport
        self._showDocumentation = showDocumentation
        self._showSettings = showSettings
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
        .posFullScreenCover(isPresented: $showOrders) {
            POSOrdersView(isPresented: $showOrders)
        }
        .posManagerOverrideModal(handler: exitOverrideHandler)
        .posManagerOverrideModal(handler: settingsOverrideHandler)
        .onAppear {
            exitOverrideHandler.configure(session: accessSession)
            settingsOverrideHandler.configure(session: accessSession)
        }
        .frame(height: Constants.size)
        .background(Color.clear)
        .animation(.default, value: backgroundAppearance)
        .posShadow(.large, cornerRadius: Constants.cornerRadius)
    }
}

private extension POSFloatingControlView {
    @ViewBuilder private func menuOptions() -> some View {
        if let staff = accessSession.currentStaff {
            Label {
                Text(operatorMenuLabel(staff))
            } icon: {
                Image(systemName: "person.circle")
            }
            .foregroundStyle(.secondary)
            .disabled(true)

            Divider()
        }

        Button {
            analytics.track(.pointOfSaleExitMenuItemTapped)
            requestExitPermission()
        } label: {
            Label(
                title: { Text(Localization.exitPointOfSale) },
                icon: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
            )
        }
        .accessibilityIdentifier("pos-exit-menu-item")
        if horizontalSizeClass == .regular || featureFlags.isFeatureFlagEnabled(.pointOfSalePhonePrototype) {
            Button {
                analytics.track(.pointOfSaleSettingsMenuItemTapped)
                requestSettingsPermission()
            } label: {
                Label(
                    title: { Text(Localization.settings) },
                    icon: { Image(systemName: "gearshape") }
                )
            }

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

            if isRolesEnabled {
                Button {
                    accessSession.lock()
                } label: {
                    Label(
                        title: { Text(Localization.lockPOS) },
                        icon: { Image(systemName: "lock") }
                    )
                }
            }
        }
    }

    func requestExitPermission() {
        guard !accessSession.allows(.editPOSSettings) else {
            showExitPOSModal = true
            return
        }
        exitOverrideHandler.requestApproval(
            for: .editPOSSettings,
            reason: Localization.exitOverrideDescription,
            onApproved: { _ in showExitPOSModal = true }
        )
    }

    func requestSettingsPermission() {
        guard !accessSession.allows(.viewPOSSettings) else {
            showSettings = true
            return
        }
        settingsOverrideHandler.requestApproval(
            for: .viewPOSSettings,
            reason: Localization.settingsOverrideDescription,
            onApproved: { _ in showSettings = true }
        )
    }

    func operatorMenuLabel(_ staff: POSStaff) -> String {
        let roleName = roleDisplayName(for: staff.role)
        if staff.displayName.caseInsensitiveCompare(roleName) == .orderedSame {
            return roleName
        }
        return "\(staff.displayName) - \(roleName)"
    }

    func roleDisplayName(for role: String) -> String {
        switch role {
        case "pos_cashier":
            return Localization.roleCashier
        case "pos_manager":
            return Localization.roleManager
        case "administrator", "shop_manager", "pos_admin":
            return Localization.roleAdmin
        default:
            return role
        }
    }

    private var isRolesEnabled: Bool {
        featureFlags.isFeatureFlagEnabled(.pointOfSaleRoles) && accessSession.pinStatus == .present
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

        static let lockPOS = NSLocalizedString(
            "pointOfSale.floatingButtons.lock.button.title",
            value: "Lock POS",
            comment: "The title of the menu button to lock Point of Sale, requiring PIN entry to continue."
        )

        static let exitOverrideDescription = NSLocalizedString(
            "pointOfSale.floatingButtons.exitOverride.description",
            value: "Exit Point of Sale",
            comment: "Description shown in the manager override modal when exiting POS requires admin approval."
        )

        static let settingsOverrideDescription = NSLocalizedString(
            "pointOfSale.floatingButtons.settingsOverride.description",
            value: "Access POS settings",
            comment: "Description shown in the manager override modal when settings access requires approval."
        )

        static let roleCashier = NSLocalizedString(
            "pointOfSale.floatingButtons.role.cashier",
            value: "Cashier",
            comment: "Display name for the cashier role shown in the POS menu."
        )

        static let roleManager = NSLocalizedString(
            "pointOfSale.floatingButtons.role.manager",
            value: "Manager",
            comment: "Display name for the manager role shown in the POS menu."
        )

        static let roleAdmin = NSLocalizedString(
            "pointOfSale.floatingButtons.role.admin",
            value: "Admin",
            comment: "Display name for the admin role shown in the POS menu."
        )
    }
}

#if DEBUG

#Preview("Reader Disconnected") {
    POSFloatingControlView(showExitPOSModal: .constant(false),
                           showSupport: .constant(false),
                           showDocumentation: .constant(false),
                           showSettings: .constant(false),
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
    return POSFloatingControlView(showExitPOSModal: .constant(false),
                                  showSupport: .constant(false),
                                  showDocumentation: .constant(false),
                                  showSettings: .constant(false),
                                  onOrdersSelected: {})
        .environment(\.posBackgroundAppearance, .primary)
        .environment(posModel)
}

#Preview("Secondary/disabled Background") {
    POSFloatingControlView(showExitPOSModal: .constant(false),
                           showSupport: .constant(false),
                           showDocumentation: .constant(false),
                           showSettings: .constant(false),
                           onOrdersSelected: {})
        .environment(\.posBackgroundAppearance, .secondary)
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#endif
