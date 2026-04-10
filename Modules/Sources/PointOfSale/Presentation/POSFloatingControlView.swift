import SwiftUI
import struct WooFoundation.WooAnalyticsEvent

struct POSFloatingControlView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posAnalytics) private var analytics
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var showExitPOSModal: Bool
    @Binding private var showSupport: Bool
    @Binding private var showDocumentation: Bool
    @Binding private var showSettings: Bool
    @State private var showProductRestrictionsModal: Bool = false
    @State private var showBarcodeScanningModal: Bool = false
    @State private var showOrders: Bool = false
    @State private var showSettingsOverride: Bool = false
    @State private var settingsOverrideState: POSManagerOverrideState = .awaitingPIN
    @State private var showExitOverride: Bool = false
    @State private var exitOverrideState: POSManagerOverrideState = .awaitingPIN
    @Environment(\.posPermissions) private var permissions
    @Environment(\.dismiss) private var dismiss

    init(showExitPOSModal: Binding<Bool>,
         showSupport: Binding<Bool>,
         showDocumentation: Binding<Bool>,
         showSettings: Binding<Bool>) {
        self._showExitPOSModal = showExitPOSModal
        self._showSupport = showSupport
        self._showDocumentation = showDocumentation
        self._showSettings = showSettings
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
        .posModal(isPresented: $showSettingsOverride) {
            POSManagerOverrideView(
                actionDescription: Localization.settingsOverrideDescription,
                capability: POSCapability.posManageSettings.rawValue,
                overrideState: $settingsOverrideState,
                onPINEntered: { pin in
                    Task { @MainActor in
                        await handleSettingsOverridePIN(pin)
                    }
                },
                onCancelled: {
                    showSettingsOverride = false
                }
            )
        }
        .posModal(isPresented: $showExitOverride) {
            POSManagerOverrideView(
                actionDescription: Localization.exitOverrideDescription,
                capability: POSCapability.posManageSettings.rawValue,
                overrideState: $exitOverrideState,
                onPINEntered: { pin in
                    Task { @MainActor in
                        await handleExitOverridePIN(pin)
                    }
                },
                onCancelled: {
                    showExitOverride = false
                }
            )
        }
        .frame(height: Constants.size)
        .background(Color.clear)
        .animation(.default, value: backgroundAppearance)
        .posShadow(.large, cornerRadius: Constants.cornerRadius)
    }
}

private extension POSFloatingControlView {
    @ViewBuilder private func menuOptions() -> some View {
        Button {
            analytics.track(.pointOfSaleExitMenuItemTapped)
            handleExitPOSTapped()
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
                requestPermissionForSettings()
            } label: {
                Label(
                    title: { Text(Localization.settings) },
                    icon: { Image(systemName: "gearshape") }
                )
            }

            if featureFlags.isFeatureFlagEnabled(.pointOfSaleHistoricalOrdersi1) {
                Button {
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersMenuItemTapped())
                    showOrders = true
                } label: {
                    Label(
                        title: { Text(Localization.orders) },
                        icon: { Image(systemName: "text.document") }
                    )
                }
            }

            if isRolesEnabled {
                Button {
                    permissions.lock()
                } label: {
                    Label(
                        title: { Text(Localization.lockPOS) },
                        icon: { Image(systemName: "lock") }
                    )
                }
            }
        }
    }

    private var isRolesEnabled: Bool {
        let flagEnabled = featureFlags.isFeatureFlagEnabled(.pointOfSaleLocalRoles) ||
            featureFlags.isFeatureFlagEnabled(.pointOfSaleRemoteRoles)
        return flagEnabled && permissions.hasAnyPINs
    }
}

// MARK: - Permission Checks

private extension POSFloatingControlView {
    func handleExitPOSTapped() {
        guard isRolesEnabled else {
            showExitPOSModal = true
            return
        }
        if permissions.currentOperator?.isAppAccountHolder == true || !permissions.isLocked {
            showExitPOSModal = true
        } else {
            exitOverrideState = .awaitingPIN
            showExitOverride = true
        }
    }

    @MainActor
    func handleExitOverridePIN(_ pin: String) async {
        do {
            _ = try await permissions.requestManagerApproval(
                managerPIN: pin,
                for: .posManageSettings,
                orderID: nil
            )
            exitOverrideState = .approved
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showExitOverride = false
                dismiss()
            }
        } catch {
            exitOverrideState = .error(message: error.posOverrideErrorMessage)
        }
    }

    func requestPermissionForSettings() {
        guard isRolesEnabled else {
            showSettings = true
            return
        }
        switch permissions.checkPermission(.posManageSettings) {
        case .allowed:
            showSettings = true
        case .requiresOverride:
            settingsOverrideState = .awaitingPIN
            showSettingsOverride = true
        }
    }

    @MainActor
    func handleSettingsOverridePIN(_ pin: String) async {
        do {
            _ = try await permissions.requestManagerApproval(
                managerPIN: pin,
                for: .posManageSettings,
                orderID: nil
            )
            settingsOverrideState = .approved
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showSettingsOverride = false
                showSettings = true
            }
        } catch {
            settingsOverrideState = .error(message: error.posOverrideErrorMessage)
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

        static let settingsOverrideDescription = NSLocalizedString(
            "pointOfSale.floatingButtons.settingsOverride.description",
            value: "Access POS settings",
            comment: "Description shown in the manager override modal when settings access requires approval."
        )

        static let exitOverrideDescription = NSLocalizedString(
            "pointOfSale.floatingButtons.exitOverride.description",
            value: "Exit Point of Sale",
            comment: "Description shown in the manager override modal when exiting POS requires admin approval."
        )
    }
}

#if DEBUG

#Preview("Reader Disconnected") {
    POSFloatingControlView(showExitPOSModal: .constant(false),
                           showSupport: .constant(false),
                           showDocumentation: .constant(false),
                           showSettings: .constant(false))
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
                                  showSettings: .constant(false))
        .environment(\.posBackgroundAppearance, .primary)
        .environment(posModel)
}

#Preview("Secondary/disabled Background") {
    POSFloatingControlView(showExitPOSModal: .constant(false),
                           showSupport: .constant(false),
                           showDocumentation: .constant(false),
                           showSettings: .constant(false))
        .environment(\.posBackgroundAppearance, .secondary)
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#endif
