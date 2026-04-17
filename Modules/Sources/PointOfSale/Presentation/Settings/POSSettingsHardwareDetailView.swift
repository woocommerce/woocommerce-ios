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
    @State private var showPrinterSetupModal: Bool = false
    @State private var showPrinterDocumentationModal: Bool = false
    @State private var showSupport: Bool = false

    private var cardReaderName: String {
        if let cardReaderName = settingsController.connectedCardReader?.name {
            return cardReaderName
        } else {
            return Localization.cardReaderNotConnected
        }
    }

    private var formattedBatteryLevel: String {
        if let batteryLevel = settingsController.connectedCardReader?.batteryLevel {
            return String(format: Localization.batteryLevelFormat, 100 * batteryLevel)
        } else {
            return Localization.batteryLevelUnknown
        }
    }

    private var formattedCardReaderFirmware: String {
        if let softwareVersion = settingsController.connectedCardReader?.softwareVersion {
            return softwareVersion
        } else {
            return Localization.firmwareVersionUnknown
        }
    }

    private var shouldShowUpdateFirmwareButton: Bool {
        posModel.isCardReaderUpdateAvailable
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
                case .hardware(.printers):
                    printersView
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
                    if case .connected = posModel.cardReaderConnectionStatus {
                        if shouldShowUpdateFirmwareButton {
                            POSSettingsCardWithIcon(title: Localization.updateFirmwareBannerTitle,
                                                    subtitle: Localization.updateFirmwareBannerSubtitle)
                        }
                        POSInformationCard {
                            VStack(spacing: POSSpacing.small) {
                                POSInformationCardFieldRow(label: Localization.readerModelTitle,
                                                           value: cardReaderName,
                                                           buttonTitle: Localization.cardReaderDisconnectTitle,
                                                           buttonAction: {
                                    posModel.disconnectCardReader()
                                })

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
                    } else {
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

    var printersView: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: Localization.printersTitle,
                backButtonConfiguration: .init(state: .enabled, action: {
                    navigationPath.removeLast()
                }, buttonIcon: "chevron.left"))
            .foregroundColor(.posSurface)

            ScrollView {
                VStack(spacing: POSSpacing.small) {
                    if case .connected = posModel.printerConnectionState {
                        POSInformationCard {
                            POSInformationCardFieldRow(label: Localization.printerStatusTitle,
                                                       value: Localization.printerStatusConnected,
                                                       buttonTitle: Localization.printerDisconnectTitle,
                                                       buttonAction: {
                                posModel.disconnectPrinter()
                            })
                        }
                    } else {
                        POSSettingsCard(title: Localization.printerSetupTitle,
                                        subtitle: Localization.printerSetupSubtitle,
                                        action: {
                            showPrinterSetupModal = true
                        })
                    }

                    POSSettingsCard(title: Localization.printerDocumentationTitle,
                                    subtitle: Localization.printerDocumentationSubtitle,
                                    action: {
                        showPrinterDocumentationModal = true
                    })
                }
                .padding(.horizontal, POSPadding.medium)
                .foregroundColor(.posOnSurface)
            }
        }
        .background(backgroundColor)
        .navigationBarBackButtonHidden(true)
        .posModal(isPresented: $showPrinterSetupModal) {
            POSPrinterSetupModal(isPresented: $showPrinterSetupModal,
                                 onConnect: {
                showPrinterSetupModal = false
                posModel.startPrinterDiscovery()
            })
        }
        .posFullScreenCover(isPresented: $showPrinterDocumentationModal) {
            SafariView(url: POSConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL())
        }
    }
}

// MARK: - Navigation
private extension POSSettingsHardwareDetailView {
    enum HardwareDestination: Identifiable, CaseIterable {
        case cardReaders
        case scanners
        case printers

        var id: Self { self }

        var title: String {
            switch self {
            case .cardReaders:
                return Localization.hardwareNavigationCardReaderTitle
            case .scanners:
                return Localization.hardwareNavigationBarcodeTitle
            case .printers:
                return Localization.hardwareNavigationPrinterTitle
            }
        }

        var subtitle: String {
            switch self {
            case .cardReaders:
                return Localization.hardwareNavigationCardReaderSubtitle
            case .scanners:
                return Localization.hardwareNavigationBarcodeSubtitle
            case .printers:
                return Localization.hardwareNavigationPrinterSubtitle
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

        static let hardwareNavigationPrinterTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.hardwareNavigationPrinterTitle",
            value: "Receipt printers",
            comment: "Navigation title of receipt printer settings."
        )

        static let hardwareNavigationPrinterSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.hardwareNavigationPrinterSubtitle",
            value: "Manage receipt printer connections",
            comment: "Description of receipt printer settings."
        )

        static let printersTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printersTitle",
            value: "Receipt printers",
            comment: "Navigation title for receipt printers settings in Point of Sale."
        )

        static let printerConnectTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerConnectTitle",
            value: "Connect printer",
            comment: "Title for printer connect button when no printer is connected."
        )

        static let printerConnectSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerConnectSubtitle",
            value: "Connect your receipt printer to start printing receipts",
            comment: "Subtitle for printer connect button when no printer is connected."
        )

        static let printerDisconnectTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerDisconnectTitle",
            value: "Disconnect printer",
            comment: "Title for printer disconnect button when printer is connected."
        )

        static let printerStatusTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerStatusTitle",
            value: "Printer",
            comment: "Label for the printer status row in settings."
        )

        static let printerStatusConnected = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerStatusConnected",
            value: "Connected",
            comment: "Status text when a receipt printer is connected."
        )

        static let printerSetupTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerSetupTitle",
            value: "Printer Setup",
            comment: "Title for printer setup option in receipt printer settings."
        )

        static let printerSetupSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerSetupSubtitle",
            value: "Configure and connect your receipt printer",
            comment: "Subtitle describing printer setup in Point of Sale settings."
        )

        static let printerDocumentationTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerDocumentationTitle",
            value: "Documentation",
            comment: "Title for receipt printer documentation option in Point of Sale settings."
        )

        static let printerDocumentationSubtitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerDocumentationSubtitle",
            value: "Learn more about receipt printing in POS",
            comment: "Subtitle describing receipt printer documentation in Point of Sale settings."
        )

        static let printerSetupStep1 = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerSetupStep1",
            value: "• Turn on your Star Micronics receipt printer and enable Bluetooth.",
            comment: "First step in printer setup instructions."
        )

        static let printerSetupStep2 = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerSetupStep2",
            value: "• Pair the printer in your iPad's Bluetooth settings (Settings → Bluetooth).",
            comment: "Second step in printer setup instructions."
        )

        static let printerSetupStep3 = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.printerSetupStep3",
            value: "• Return here and tap \"Connect printer\" to start using it.",
            comment: "Third step in printer setup instructions."
        )

        static let supportCancel = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.help.support.cancel",
            value: "Cancel",
            comment: "Button to dismiss the support form from POS settings."
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
