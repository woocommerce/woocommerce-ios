import SwiftUI
import struct WooFoundation.SafariView

struct POSSettingsHardwareDetailView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.posAnalytics) private var analytics

    let settingsController: PointOfSaleSettingsControllerProtocol

    @State private var navigationPath: [NavigationDestination] = []
    @State private var showBarcodeScanningSetupModal: Bool = false
    @State private var showBarcodeScanningDocumentationModal: Bool = false
    @State private var showCardReaderDocumentationModal: Bool = false

    private var cardReaderName: String {
        if let cardReaderName = settingsController.connectedCardReader?.name {
            return cardReaderName
        } else {
            return Localization.cardReaderNotConnected
        }
    }

    private var formattedBatteryLevel: String {
        if let batteryLevel = settingsController.connectedCardReader?.batteryLevel {
            let percentage = Int(batteryLevel * 100)
            return "\(percentage)%"
        } else {
            return Localization.batteryLevelUnknown
        }
    }

    private var backgroundColor: Color {
        Color.posOnSecondaryContainer
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            POSPageHeaderView(title: Localization.hardwareTitle)
            .foregroundColor(.posSurface)
            .accessibilityAddTraits(.isHeader)

            List(HardwareDestination.allCases) { destination in
                NavigationLink(value: NavigationDestination.hardware(destination)) {
                    VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                        Text(destination.title)
                            .font(.posBodyLargeRegular())
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
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(backgroundColor)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .hardware(.cardReaders):
                    cardReadersView
                case .hardware(.scanners):
                    scannersView
                }
            }
            .posModal(isPresented: $showBarcodeScanningSetupModal) {
                PointOfSaleBarcodeScannerSetup(isPresented: $showBarcodeScanningSetupModal, analytics: analytics)
            }
            .posFullScreenCover(isPresented: $showBarcodeScanningDocumentationModal) {
                SafariView(url: POSConstants.URLs.pointOfSaleBarcodeScannerDocumentation.asURL())
            }
        }
    }

    private func handleScannerDestination(_ destination: ScannerDestination) {
        switch destination {
        case .setup:
            showBarcodeScanningSetupModal = true
        case .documentation:
            showBarcodeScanningDocumentationModal = true
        }
    }

    private var cardReadersView: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: Localization.cardReadersTitle,
                backButtonConfiguration: .init(state: .enabled, action: {
                    navigationPath.removeLast()
                }, buttonIcon: "chevron.left"))
            .foregroundColor(.posSurface)

            List {
                VStack(spacing: POSPadding.xSmall) {
                    HStack {
                        Text(Localization.readerModelTitle)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(cardReaderName)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    HStack {
                        Text(Localization.readerBatteryTitle)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(formattedBatteryLevel)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                POSSettingsCardView(
                    title: Localization.cardReaderDocumentationTitle,
                    subtitle: Localization.cardReaderDocumentationSubtitle,
                    action: { showCardReaderDocumentationModal = true }
                )
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .listRowBackground(Color.clear)
            .background(backgroundColor)
            .foregroundColor(.posOnSurface)
        }
        .navigationBarBackButtonHidden(true)
        .posFullScreenCover(isPresented: $showCardReaderDocumentationModal) {
            SafariView(url: POSConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL())
        }
    }

    private var scannersView: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: Localization.scannersTitle,
                backButtonConfiguration: .init(state: .enabled, action: {
                    navigationPath.removeLast()
                }, buttonIcon: "chevron.left"))
            .foregroundColor(.posSurface)

            List(ScannerDestination.allCases) { destination in
                Button {
                    handleScannerDestination(destination)
                } label: {
                    HStack(spacing: POSSpacing.medium) {
                        Image(systemName: destination.icon)
                            .font(.posBodyLargeRegular())
                            .accessibilityHidden(true)
                            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
                        VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                            Text(destination.title)
                                .font(.posBodyLargeRegular())
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                            Text(destination.subtitle)
                                .font(.posBodyMediumRegular())
                                .foregroundStyle(.secondary)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        }
                        Spacer()
                    }
                }
                .accessibilityAddTraits(.isButton)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .listRowBackground(Color.clear)
            .background(backgroundColor)
            .foregroundColor(.posOnSurface)
        }
        .navigationBarBackButtonHidden(true)
    }
}

extension POSSettingsHardwareDetailView {
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

        var icon: String {
            switch self {
            case .cardReaders:
                return "creditcard"
            case .scanners:
                return "qrcode.viewfinder"
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

        var icon: String {
            switch self {
            case .setup:
                return "gearshape"
            case .documentation:
                return "doc.text"
            }
        }
    }
}

private extension POSSettingsHardwareDetailView {
    enum Localization {
        static let readerModelTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.readerModelTitle",
            value: "Model",
            comment: "Text displayed on Point of Sale settings pointing to the card reader model."
        )

        static let readerBatteryTitle = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.readerBatteryTitle",
            value: "Battery",
            comment: "Text displayed on Point of Sale settings pointing to the card reader battery."
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
    }
}

//#if DEBUG
//#Preview {
//    PointOfSaleSettingsHardwareDetailView(settingsController: PointOfSaleSettingsPreviewController())
//        .environment(\.posAnalytics, MockPOSAnalytics())
//}
//#endif
