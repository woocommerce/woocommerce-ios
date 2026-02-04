import SwiftUI
import struct WooFoundation.SafariView

struct POSSettingsHardwareDetailView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posExternalViews) private var externalViews

    let settingsController: POSSettingsControllerProtocol

    @State private var navigationPath: [NavigationDestination] = []
    @State private var showBarcodeScanningSetupModal: Bool = false
    @State private var showBarcodeScanningDocumentationModal: Bool = false
    @State private var showCardReaderDocumentationModal: Bool = false
    @State private var showSupport: Bool = false
    @State private var isCancellingReconnection: Bool = false

    private var cardReaderName: String {
        settingsController.connectedCardReader?.name ?? Localization.cardReaderNotConnected
    }

    private var formattedBatteryLevel: String {
        guard let batteryLevel = settingsController.connectedCardReader?.batteryLevel else {
            return Localization.batteryLevelUnknown
        }
        return String(format: Localization.batteryLevelFormat, 100 * batteryLevel)
    }

    private var formattedCardReaderFirmware: String {
        settingsController.connectedCardReader?.softwareVersion ?? Localization.firmwareVersionUnknown
    }

    private var isReconnecting: Bool {
        if case .reconnecting = posModel.cardReaderConnectionStatus {
            return true
        }
        return false
    }

    private var shouldShowUpdateFirmwareButton: Bool {
        posModel.isCardReaderUpdateAvailable && !isReconnecting
    }

    private var backgroundColor: Color {
        Color.posSurface
    }

    var body: some View {
        @Bindable var posModel = posModel
        NavigationStack(path: $navigationPath) {
            VStack(spacing: POSSpacing.none) {
                POSPageHeaderView(title: Localization.hardwareTitle)
                    .foregroundColor(.posSurface)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: POSSpacing.small) {
                    ForEach(HardwareDestination.allCases) { destination in
                        NavigationLink(value: NavigationDestination.hardware(destination)) {
                            VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                                Text(destination.title)
                                    .font(.posBodyLargeBold)
                                    .foregroundStyle(Color.posOnSurface)
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                                Text(destination.subtitle)
                                    .font(.posBodyMediumRegular())
                                    .foregroundStyle(.secondary)
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.posSurfaceContainerLowest)
                            .posItemCardBorderStyles()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(destination.title), \(destination.subtitle)")
                    }
                }
                .padding(.horizontal, POSPadding.medium)

                Spacer()
            }
            .background(backgroundColor)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .hardware(.cardReaders):
                    cardReadersView
                case .hardware(.scanners):
                    scannersView
                }
            }
            .posModal(item: $posModel.cardPresentPaymentAlertViewModel, onDismiss: {
                posModel.cardPresentPaymentAlertViewModel?.onDismiss?()
            }, content: { alertType in
                PointOfSaleCardPresentPaymentAlert(alertType: alertType)
                    .posInteractiveDismissDisabled(alertType.isDismissDisabled)
            })
            .posModal(item: $posModel.cardPresentPaymentOnboardingViewContainer, onDismiss: {
                posModel.cancelCardPaymentsOnboarding()
            }, content: { viewContainer in
                paymentsOnboardingView(from: viewContainer)
            })
            .posSheet(isPresented: $showSupport) {
                supportForm
                    .interactiveDismissDisabled(true)
            }
            .posModal(isPresented: $showBarcodeScanningSetupModal) {
                POSBarcodeScannerSetup(isPresented: $showBarcodeScanningSetupModal, analytics: analytics)
            }
            .posFullScreenCover(isPresented: $showBarcodeScanningDocumentationModal) {
                SafariView(url: POSConstants.URLs.pointOfSaleBarcodeScannerDocumentation.asURL())
            }
        }
    }
}

// MARK: - Views
private extension POSSettingsHardwareDetailView {
    func paymentsOnboardingView(from onboardingViewContainer: CardPresentPaymentOnboardingViewContainer) -> some View {
        onboardingViewContainer.configuration.showSupport = {
            posModel.cancelCardPaymentsOnboarding()
            showSupport = true
        }

        return PointOfSaleCardPresentPaymentOnboardingView(
            viewModel: .init(onboardingViewContainer: onboardingViewContainer,
                             onDismissTap: {
                                 posModel.cancelCardPaymentsOnboarding()
                             }))
        .onAppear {
            posModel.trackCardPaymentsOnboardingShown()
        }
    }

    var supportForm: some View {
        NavigationStack {
            externalViews.createSupportFormView(isPresented: $showSupport, sourceTag: Constants.supportTag)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.supportCancel) {
                        showSupport = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    var cardReaderNameRow: some View {
        VStack(alignment: .leading, spacing: POSPadding.small) {
            HStack(alignment: .center, spacing: POSSpacing.medium) {
                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(Localization.readerModelTitle)
                        .font(.posBodyMediumRegular())
                    Text(cardReaderName)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isReconnecting {
                    reconnectingMenuButton
                } else {
                    Button(Localization.cardReaderDisconnectTitle) {
                        posModel.disconnectCardReader()
                    }
                    .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: .default, isLoading: false))
                }
            }

            Divider()
                .padding(.top, POSPadding.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var reconnectingMenuButton: some View {
        Menu {
            Button(Localization.cancelReconnectionTitle) {
                isCancellingReconnection = true
                posModel.cancelReconnection()
            }
        } label: {
            HStack(spacing: POSSpacing.small) {
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle(size: 16, lineWidth: 4))
                Text(isCancellingReconnection ? Localization.cancellingReconnectionTitle : Localization.reconnectingButtonTitle)
            }
            .font(.posBodySmallBold())
            .foregroundColor(.posOnSurface)
            .padding(.vertical, POSPadding.small)
            .padding(.horizontal, POSPadding.medium)
            .background(Color.posSurfaceContainerLowest)
            .cornerRadius(POSCornerRadiusStyle.small.value)
            .overlay(
                RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value)
                    .strokeBorder(Color.posOnSurface, lineWidth: 2)
            )
        }
        .disabled(isCancellingReconnection)
        .onAppear {
            isCancellingReconnection = false
        }
    }

    var cardReadersView: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: Localization.cardReadersTitle,
                backButtonConfiguration: .init(state: .enabled, action: {
                    navigationPath.removeLast()
                }, buttonIcon: "chevron.left"))
            .foregroundColor(.posSurface)

            ScrollView {
                VStack(spacing: POSSpacing.small) {
                    switch posModel.cardReaderConnectionStatus {
                    case .connected, .reconnecting:
                        if shouldShowUpdateFirmwareButton {
                            POSSettingsCardWithIcon(title: Localization.updateFirmwareBannerTitle,
                                                    subtitle: Localization.updateFirmwareBannerSubtitle)
                        }
                        POSInformationCard {
                            VStack(spacing: POSSpacing.small) {
                                cardReaderNameRow

                                POSInformationCardFieldRow(label: Localization.readerBatteryTitle,
                                                           value: formattedBatteryLevel)

                                POSInformationCardFieldRow(label: Localization.firmwareTitle,
                                                           value: formattedCardReaderFirmware,
                                                           showSeparator: false,
                                                           buttonTitle: shouldShowUpdateFirmwareButton ? Localization.updateFirmwareButtontitle : nil,
                                                           buttonAction: shouldShowUpdateFirmwareButton ? {
                                    posModel.updateCardReaderSoftware()
                                } : nil,
                                                           buttonStyle: .primary)
                            }
                        }
                    default:
                        POSSettingsCard(title: Localization.cardReaderConnectTitle,
                                        subtitle: Localization.cardReaderConnectSubtitle,
                                        action: {
                            posModel.connectCardReader()
                        })
                    }

                    POSSettingsCard(title: Localization.cardReaderDocumentationTitle,
                                    subtitle: Localization.cardReaderDocumentationSubtitle,
                                    action: { showCardReaderDocumentationModal = true })
                    .accessibilityAddTraits(.isButton)
                }
                .padding(.horizontal, POSPadding.medium)
                .foregroundColor(.posOnSurface)
            }
        }
        .background(backgroundColor)
        .navigationBarBackButtonHidden(true)
        .posFullScreenCover(isPresented: $showCardReaderDocumentationModal) {
            SafariView(url: POSConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL())
        }
    }

    var scannersView: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: Localization.scannersTitle,
                backButtonConfiguration: .init(state: .enabled, action: {
                    navigationPath.removeLast()
                }, buttonIcon: "chevron.left"))
            .foregroundColor(.posSurface)

            VStack(spacing: POSSpacing.small) {
                ForEach(ScannerDestination.allCases) { destination in
                    POSSettingsCard(
                        title: destination.title,
                        subtitle: destination.subtitle,
                        action: {
                            handleScannerDestination(destination)
                        }
                    )
                }
            }
            .padding(.horizontal, POSPadding.medium)

            Spacer()
        }
        .background(backgroundColor)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Navigation
private extension POSSettingsHardwareDetailView {
    enum HardwareDestination: Identifiable, CaseIterable {
        case cardReaders
        case scanners

        var id: Self { self }

        var title: String {
            switch self {
            case .cardReaders:
                return Localization.hardwareNavigationCardReaderTitle
            case .scanners:
                return Localization.hardwareNavigationBarcodeTitle
            }
        }

        var subtitle: String {
            switch self {
            case .cardReaders:
                return Localization.hardwareNavigationCardReaderSubtitle
            case .scanners:
                return Localization.hardwareNavigationBarcodeSubtitle
            }
        }
    }

    enum NavigationDestination: Hashable {
        case hardware(HardwareDestination)
    }

    enum ScannerDestination: Identifiable, CaseIterable {
        case setup
        case documentation

        var id: Self { self }

        var title: String {
            switch self {
            case .setup:
                return Localization.scannerSetupTitle
            case .documentation:
                return Localization.scannerDocumentationTitle
            }
        }

        var subtitle: String {
            switch self {
            case .setup:
                return Localization.scannerSetupSubtitle
            case .documentation:
                return Localization.scannerDocumentationSubtitle
            }
        }
    }

    func handleScannerDestination(_ destination: ScannerDestination) {
        switch destination {
        case .setup:
            showBarcodeScanningSetupModal = true
        case .documentation:
            showBarcodeScanningDocumentationModal = true
        }
    }
}

// MARK: - Constants
private extension POSSettingsHardwareDetailView {
    enum Constants {
        static let supportTag = "origin:point-of-sale"
    }

    enum Localization {
        static let readerModelTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.readerModelTitle.1",
            value: "Device name",
            comment: "Text displayed on Point of Sale settings pointing to the card reader model."
        )

        static let readerBatteryTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.readerBatteryTitle",
            value: "Battery",
            comment: "Text displayed on Point of Sale settings pointing to the card reader battery."
        )

        static let batteryLevelFormat = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.batteryLevelFormat",
            value: "%.0f%%",
            comment: "Format string for displaying battery level percentage in Point of Sale settings. " +
                "Please leave the %.0f%% intact, as it represents the battery percentage."
        )

        static let cardReaderNotConnected = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cardReaderNotConnected",
            value: "Reader not connected",
            comment: "Text displayed on Point of Sale settings when the card reader is not connected."
        )

        static let batteryLevelUnknown = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.batteryLevelUnknown",
            value: "Unknown",
            comment: "Text displayed on Point of Sale settings when card reader battery is unknown."
        )

        static let firmwareVersionUnknown = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.firmwareVersionUnknown",
            value: "Unknown",
            comment: "Text displayed on Point of Sale settings when card reader firmware version is unknown."
        )

        static let hardwareTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.hardwareTitle",
            value: "Hardware",
            comment: "Navigation title for the hardware settings list."
        )

        static let cardReadersTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cardReadersTitle",
            value: "Card readers",
            comment: "Navigation title for card readers settings in Point of Sale."
        )

        static let scannersTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.scannersTitle",
            value: "Barcode scanners",
            comment: "Navigation title for barcode scanners settings in Point of Sale."
        )

        static let scannerSetupTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.scannerSetupTitle",
            value: "Scanner Setup",
            comment: "Title for scanner setup option in barcode scanners settings in Point of Sale."
        )

        static let scannerSetupSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.scannerSetupSubtitle",
            value: "Configure and test your barcode scanner",
            comment: "Subtitle describing scanner setup in Point of Sale settings."
        )

        static let scannerDocumentationTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.scannerDocumentationTitle",
            value: "Documentation",
            comment: "Title for barcode scanner documentation option in Point of Sale settings."
        )

        static let scannerDocumentationSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.scannerDocumentationSubtitle",
            value: "Learn more about barcode scanning in POS",
            comment: "Subtitle describing barcode scanner documentation in Point of Sale settings."
        )

        static let cardReaderDocumentationTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cardReaderDocumentationTitle",
            value: "Documentation",
            comment: "Title for card reader documentation option in Point of Sale settings."
        )

        static let cardReaderDocumentationSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cardReaderDocumentationSubtitle",
            value: "Learn more about accepting mobile payments",
            comment: "Subtitle describing card reader documentation in Point of Sale settings."
        )

        static let hardwareNavigationBarcodeTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.hardwareNavigationBarcodeTitle",
            value: "Barcode scanners",
            comment: "Navigation title of Barcode scanner settings."
        )

        static let hardwareNavigationCardReaderTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.hardwareNavigationCardReaderTitle",
            value: "Card readers",
            comment: "Navigation title of Card reader settings."
        )

        static let hardwareNavigationCardReaderSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.hardwareNavigationCardReaderSubtitle",
            value: "Manage card reader connections",
            comment: "Description of Card reader settings for connections."
        )

        static let hardwareNavigationBarcodeSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.hardwareNavigationBarcodeSubtitle",
            value: "Configure barcode scanner settings",
            comment: "Description of Barcode scanner settings configuration."
        )

        static let cardReaderConnectTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cardReaderConnectTitle",
            value: "Connect card reader",
            comment: "Title for card reader connect button when no reader is connected."
        )

        static let cardReaderDisconnectTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cardReaderDisconnectTitle",
            value: "Disconnect reader",
            comment: "Title for card reader disconnect button when reader is already connected."
        )

        static let cardReaderConnectSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cardReaderConnectSubtitle",
            value: "Connect your card reader and start accepting payments",
            comment: "Subtitle for card reader connect button when no reader is connected."
        )

        static let firmwareTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.firmwareTitle",
            value: "Firmware",
            comment: "Title for the card reader firmware section in Point of Sale settings."
        )

        static let updateFirmwareButtontitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.updateFirmwareButtontitle",
            value: "Update firmware",
            comment: "Title of the button to update firmware in Point of Sale settings."
        )

        static let updateFirmwareBannerTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.updateFirmwareBannerTitle",
            value: "Update firmware version",
            comment: "Title for the CTA banner to update firmware in Point of Sale settings."
        )

        static let updateFirmwareBannerSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.updateFirmwareBannerSubtitle",
            value: "Update the firmware version to continue accepting payments.",
            comment: "Subtitle for the CTA banner to update firmware in Point of Sale settings."
        )

        static let supportCancel = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.help.support.cancel",
            value: "Cancel",
            comment: "Button to dismiss the support form from POS settings."
        )

        static let reconnectingButtonTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.reconnectingButtonTitle",
            value: "Reconnecting…",
            comment: "Button title shown when card reader is reconnecting in POS settings."
        )

        static let cancelReconnectionTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cancelReconnectionTitle",
            value: "Cancel reconnection",
            comment: "Menu option to cancel card reader reconnection in POS settings."
        )

        static let cancellingReconnectionTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cancellingReconnectionTitle",
            value: "Cancelling…",
            comment: "Button title shown when card reader reconnection is being cancelled in POS settings."
        )
    }
}

private extension POSSettingsHardwareDetailView {
    struct POSSettingsCardWithIcon: View {
        let title: String
        let subtitle: String

        init(title: String, subtitle: String) {
            self.title = title
            self.subtitle = subtitle
        }

        var body: some View {
            HStack(alignment: .center, spacing: POSPadding.medium) {
                Image(systemName: "info.circle")
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                    Text(title)
                        .font(.posBodyLargeBold)
                        .foregroundStyle(Color.posOnSurface)
                    Text(subtitle)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.posSurfaceContainerLowest)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .posItemCardBorderStyles()
            .accessibilityLabel("\(title), \(subtitle)")
        }
    }
}

#if DEBUG
#Preview {
    POSSettingsHardwareDetailView(settingsController: POSSettingsPreviewController())
}
#endif
