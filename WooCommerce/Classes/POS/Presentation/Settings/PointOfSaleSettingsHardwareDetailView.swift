import SwiftUI

struct PointOfSaleSettingsHardwareDetailView: View {
    let settingsController: PointOfSaleSettingsControllerProtocol

    @State private var navigationPath: [NavigationDestination] = []
    @State private var showBarcodeScanningSetupModal: Bool = false
    @State private var showBarcodeScanningDocumentationModal: Bool = false
    @State private var showCardReaderDocumentationModal: Bool = false

    private var cardReaderName: String {
        if let cardReaderName = settingsController.connectedCardReader?.name {
            return cardReaderName
        } else {
            return Localization.cardReaderNotSet
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

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List(HardwareDestination.allCases) { destination in
                NavigationLink(value: NavigationDestination.hardware(destination)) {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: destination.icon)
                            .font(.posBodyLargeRegular())
                        VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                            Text(destination.title)
                                .font(.posBodyLargeRegular())
                            Text(destination.subtitle)
                                .font(.posBodyMediumRegular())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .hardware(.cardReaders):
                    cardReadersView
                case .hardware(.scanners):
                    scannersView
                }
            }
            .posModal(isPresented: $showBarcodeScanningSetupModal) {
                PointOfSaleBarcodeScannerSetup(isPresented: $showBarcodeScanningSetupModal)
            }
            .posFullScreenCover(isPresented: $showBarcodeScanningDocumentationModal) {
                SafariView(url: WooConstants.URLs.pointOfSaleDocumentation.asURL())
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
        VStack(spacing: POSSpacing.large) {
            List {
                VStack(spacing: POSPadding.xSmall) {
                    HStack {
                        Text("Model")
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(cardReaderName)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    HStack {
                        Text("Battery")
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(formattedBatteryLevel)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                Button {
                    showCardReaderDocumentationModal = true
                } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "doc.text")
                            .font(.posBodyLargeRegular())
                        VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                            Text(Localization.cardReaderDocumentationTitle)
                                .font(.posBodyLargeRegular())
                            Text(Localization.cardReaderDocumentationSubtitle)
                                .font(.posBodyMediumRegular())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(Localization.cardReadersTitle)
        .posFullScreenCover(isPresented: $showCardReaderDocumentationModal) {
            SafariView(url: WooConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL())
        }
    }

    private var scannersView: some View {
        List(ScannerDestination.allCases) { destination in
            Button {
                handleScannerDestination(destination)
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: destination.icon)
                        .font(.posBodyLargeRegular())
                    VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                        Text(destination.title)
                            .font(.posBodyLargeRegular())
                        Text(destination.subtitle)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle(Localization.scannersTitle)
    }

}

extension PointOfSaleSettingsHardwareDetailView {
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

private extension PointOfSaleSettingsHardwareDetailView {
    enum Localization {
        static let cardReaderNotSet = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.cardReaderNotSet",
            value: "Not set",
            comment: "Text displayed on Point of Sale settings when any setting has not been provided."
        )

        static let batteryLevelUnknown = NSLocalizedString(
            "pointOfSaleSettingsHardwareDetailView.batteryLevelUnknown",
            value: "Unknown",
            comment: "Text displayed on Point of Sale settings when card reader battery is unknown."
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

#Preview {
    PointOfSaleSettingsHardwareDetailView(settingsController: PointOfSaleSettingsPreviewController())
}
